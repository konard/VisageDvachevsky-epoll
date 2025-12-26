#!/bin/bash
# Deep profiling script for KATANA HTTP server
# Captures CPU, syscall, and performance metrics under load

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${PROJECT_ROOT}/profiling_output/$(date +%Y%m%d_%H%M%S)"
PORT=18093
DURATION=10
CONCURRENCY=4

mkdir -p "$OUTPUT_DIR"

echo "=== KATANA Deep Profiling Script ==="
echo "Output directory: $OUTPUT_DIR"
echo "Port: $PORT"
echo "Duration: ${DURATION}s per test"
echo ""

# Start server
echo "[1/5] Starting hello_world_server..."
HELLO_PORT=$PORT "$PROJECT_ROOT/build/bench/hello_world_server" > "$OUTPUT_DIR/server.log" 2>&1 &
SERVER_PID=$!
sleep 2

# Verify server is running
if ! curl -s "http://127.0.0.1:$PORT/" > /dev/null; then
    echo "ERROR: Server failed to start"
    kill $SERVER_PID 2>/dev/null || true
    exit 1
fi
echo "Server PID: $SERVER_PID"

cleanup() {
    echo "Cleaning up..."
    kill $SERVER_PID 2>/dev/null || true
}
trap cleanup EXIT

# Test 1: Keep-alive benchmark with syscall tracing
echo ""
echo "[2/5] Running keep-alive benchmark with syscall tracing..."
strace -c -f -p $SERVER_PID -o "$OUTPUT_DIR/strace_keepalive.txt" &
STRACE_PID=$!
sleep 1

ab -n 10000 -c $CONCURRENCY -k "http://127.0.0.1:$PORT/" > "$OUTPUT_DIR/ab_keepalive.txt" 2>&1

kill $STRACE_PID 2>/dev/null || true
wait $STRACE_PID 2>/dev/null || true
sleep 1

echo "Keep-alive syscall trace saved to: $OUTPUT_DIR/strace_keepalive.txt"

# Test 2: Close-churn benchmark with syscall tracing
echo ""
echo "[3/5] Running close-churn benchmark with syscall tracing..."
strace -c -f -p $SERVER_PID -o "$OUTPUT_DIR/strace_closechurn.txt" &
STRACE_PID=$!
sleep 1

# Run without keep-alive (each request closes connection)
ab -n 5000 -c $CONCURRENCY "http://127.0.0.1:$PORT/" > "$OUTPUT_DIR/ab_closechurn.txt" 2>&1

kill $STRACE_PID 2>/dev/null || true
wait $STRACE_PID 2>/dev/null || true
sleep 1

echo "Close-churn syscall trace saved to: $OUTPUT_DIR/strace_closechurn.txt"

# Test 3: CPU profiling with perf record
echo ""
echo "[4/5] Running CPU profiling with perf record..."
perf record -F 99 -g -p $SERVER_PID -o "$OUTPUT_DIR/perf.data" -- sleep $DURATION &
PERF_PID=$!

# Generate load during profiling
ab -n 50000 -c 8 -k "http://127.0.0.1:$PORT/" > "$OUTPUT_DIR/ab_perf.txt" 2>&1

wait $PERF_PID 2>/dev/null || true

# Generate perf report
perf report -i "$OUTPUT_DIR/perf.data" --stdio > "$OUTPUT_DIR/perf_report.txt" 2>&1 || echo "perf report failed"

# Try to generate flamegraph if tools are available
if command -v stackcollapse-perf.pl &> /dev/null; then
    perf script -i "$OUTPUT_DIR/perf.data" | stackcollapse-perf.pl > "$OUTPUT_DIR/perf.folded"
    flamegraph.pl < "$OUTPUT_DIR/perf.folded" > "$OUTPUT_DIR/flamegraph.svg"
    echo "Flamegraph saved to: $OUTPUT_DIR/flamegraph.svg"
elif [ -d "$HOME/FlameGraph" ]; then
    perf script -i "$OUTPUT_DIR/perf.data" | "$HOME/FlameGraph/stackcollapse-perf.pl" > "$OUTPUT_DIR/perf.folded"
    "$HOME/FlameGraph/flamegraph.pl" < "$OUTPUT_DIR/perf.folded" > "$OUTPUT_DIR/flamegraph.svg"
    echo "Flamegraph saved to: $OUTPUT_DIR/flamegraph.svg"
else
    echo "FlameGraph tools not found - skipping flamegraph generation"
fi

echo "CPU profile saved to: $OUTPUT_DIR/perf_report.txt"

# Test 4: Hardware counters with perf stat
echo ""
echo "[5/5] Collecting hardware performance counters..."
perf stat -e cycles,instructions,cache-references,cache-misses,branches,branch-misses \
    -p $SERVER_PID -o "$OUTPUT_DIR/perf_stat.txt" -- sleep 5 &
PERF_STAT_PID=$!

ab -n 20000 -c 8 -k "http://127.0.0.1:$PORT/" > "$OUTPUT_DIR/ab_hwcounters.txt" 2>&1

wait $PERF_STAT_PID 2>/dev/null || true

echo "Hardware counters saved to: $OUTPUT_DIR/perf_stat.txt"

# Generate summary
echo ""
echo "=== Profiling Complete ==="
echo ""
echo "Output files:"
ls -la "$OUTPUT_DIR/"

echo ""
echo "=== Keep-Alive Benchmark Summary ==="
grep -E "Requests per second|Time per request|Failed" "$OUTPUT_DIR/ab_keepalive.txt" || true

echo ""
echo "=== Close-Churn Benchmark Summary ==="
grep -E "Requests per second|Time per request|Failed" "$OUTPUT_DIR/ab_closechurn.txt" || true

echo ""
echo "=== Top Syscalls (Keep-Alive) ==="
head -20 "$OUTPUT_DIR/strace_keepalive.txt" || true

echo ""
echo "=== Top Syscalls (Close-Churn) ==="
head -20 "$OUTPUT_DIR/strace_closechurn.txt" || true

echo ""
echo "=== Hardware Counters ==="
cat "$OUTPUT_DIR/perf_stat.txt" || true

# Cleanup happens via trap
