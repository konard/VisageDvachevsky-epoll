#!/usr/bin/env python3
"""
Close mode load test for KATANA HTTP server.

This test verifies that the server handles many short-lived connections
correctly when clients request "Connection: close". This tests the
accept loop resilience fix for issue #1.

Usage:
    python3 close_mode_test.py [--host HOST] [--port PORT] [--threads N] [--duration SECS]

Example:
    python3 close_mode_test.py --threads 16 --duration 10

The test passes if:
1. No ECONNREFUSED errors occur
2. At least 100 successful requests are made
3. Error rate is below 1%
"""

import argparse
import http.client
import json
import socket
import threading
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class TestStats:
    """Thread-safe test statistics."""
    lock: threading.Lock = field(default_factory=threading.Lock)
    success: int = 0
    errors: Counter = field(default_factory=Counter)
    latencies: list = field(default_factory=list)

    def record_success(self, latency_ms: float):
        with self.lock:
            self.success += 1
            self.latencies.append(latency_ms)

    def record_error(self, error_type: str):
        with self.lock:
            self.errors[error_type] += 1


def make_request(host: str, port: int, stats: TestStats) -> bool:
    """Make a single POST request with Connection: close."""
    start = time.monotonic()
    try:
        conn = http.client.HTTPConnection(host, port, timeout=5)
        headers = {
            "Connection": "close",
            "Content-Type": "application/json"
        }
        body = "[1.0, 2.0, 3.0]"
        conn.request("POST", "/compute/sum", body, headers)
        response = conn.getresponse()
        response.read()  # Consume the body
        conn.close()

        latency_ms = (time.monotonic() - start) * 1000
        if response.status == 200:
            stats.record_success(latency_ms)
            return True
        else:
            stats.record_error(f"status_{response.status}")
            return False

    except ConnectionRefusedError:
        stats.record_error("ECONNREFUSED")
        return False
    except ConnectionResetError:
        stats.record_error("ECONNRESET")
        return False
    except socket.timeout:
        stats.record_error("timeout")
        return False
    except OSError as e:
        stats.record_error(f"OSError_{e.errno}")
        return False
    except Exception as e:
        stats.record_error(f"other_{type(e).__name__}")
        return False


def worker_loop(host: str, port: int, stats: TestStats, stop_event: threading.Event):
    """Worker that continuously makes requests until stopped."""
    while not stop_event.is_set():
        make_request(host, port, stats)


def run_test(host: str, port: int, threads: int, duration: float) -> TestStats:
    """Run the load test."""
    stats = TestStats()
    stop_event = threading.Event()

    print(f"Starting load test: {threads} threads, {duration}s duration")
    print(f"Target: http://{host}:{port}/compute/sum")
    print(f"Mode: Connection: close")
    print("-" * 50)

    # Start worker threads
    workers = []
    for _ in range(threads):
        t = threading.Thread(target=worker_loop, args=(host, port, stats, stop_event))
        t.daemon = True
        t.start()
        workers.append(t)

    # Wait for duration
    try:
        time.sleep(duration)
    except KeyboardInterrupt:
        print("\nInterrupted by user")

    # Signal stop and wait
    stop_event.set()
    for t in workers:
        t.join(timeout=1.0)

    return stats


def print_results(stats: TestStats, duration: float):
    """Print test results."""
    print("\n" + "=" * 50)
    print("RESULTS")
    print("=" * 50)

    total = stats.success + sum(stats.errors.values())
    error_count = sum(stats.errors.values())
    error_rate = (error_count / total * 100) if total > 0 else 0

    print(f"Total requests:    {total}")
    print(f"Successful:        {stats.success}")
    print(f"Errors:            {error_count} ({error_rate:.2f}%)")
    print(f"Throughput:        {total / duration:.2f} req/s")

    if stats.latencies:
        latencies = sorted(stats.latencies)
        print(f"\nLatency (ms):")
        print(f"  avg:  {sum(latencies) / len(latencies):.2f}")
        print(f"  p50:  {latencies[len(latencies) // 2]:.2f}")
        print(f"  p99:  {latencies[int(len(latencies) * 0.99)]:.2f}")
        print(f"  max:  {max(latencies):.2f}")

    if stats.errors:
        print(f"\nErrors by type:")
        for error_type, count in sorted(stats.errors.items(), key=lambda x: -x[1]):
            print(f"  {error_type}: {count}")

    # Verdict
    print("\n" + "-" * 50)
    econnrefused = stats.errors.get("ECONNREFUSED", 0)
    if econnrefused > 0:
        print("FAIL: ECONNREFUSED errors detected!")
        print("      This indicates the accept loop bug may have regressed.")
        return False
    elif stats.success < 100:
        print("FAIL: Too few successful requests (< 100)")
        return False
    elif error_rate > 1.0:
        print(f"WARN: High error rate ({error_rate:.2f}%)")
        return False
    else:
        print("PASS: No ECONNREFUSED, acceptable error rate")
        return True


def main():
    parser = argparse.ArgumentParser(description="Connection: close load test")
    parser.add_argument("--host", default="localhost", help="Server host")
    parser.add_argument("--port", type=int, default=8080, help="Server port")
    parser.add_argument("--threads", type=int, default=16, help="Number of threads")
    parser.add_argument("--duration", type=float, default=10, help="Test duration in seconds")
    args = parser.parse_args()

    stats = run_test(args.host, args.port, args.threads, args.duration)
    success = print_results(stats, args.duration)
    return 0 if success else 1


if __name__ == "__main__":
    exit(main())
