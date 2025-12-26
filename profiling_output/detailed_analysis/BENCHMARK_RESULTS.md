# KATANA Framework - Benchmark Results

Generated: 2025-12-26 14:59:01

**Note**: Measurements use time-boxed phases with warm-ups, steady-state sampling, and full response validation.


## Core Performance

| Benchmark | Value | Unit |
|-----------|-------|------|
| Latency samples | 87614.000 | samples |
| Latency avg | 0.180 | ms |
| Latency p50 | 0.113 | ms |
| Latency p90 | 0.167 | ms |
| Latency p95 | 0.188 | ms |
| Latency p99 | 0.245 | ms |
| Latency p999 | 18.141 | ms |
| Latency IQR | 0.043 | ms |
| Latency max | 179.076 | ms |
| Keep-alive throughput | 10594.037 | req/s |
| Keep-alive success | 4996.000 | requests |

## HTTP Parsing

| Benchmark | Value | Unit |
|-----------|-------|------|
| Minimal request samples | 1500.000 | samples |
| Minimal request p50 | 0.108 | ms |
| Minimal request p99 | 0.160 | ms |
| Medium request samples | 1500.000 | samples |
| Medium request p50 | 0.096 | ms |
| Medium request p99 | 0.139 | ms |
| Large headers samples | 1500.000 | samples |
| Large headers p50 | 0.094 | ms |
| Large headers p99 | 0.121 | ms |

## Scalability

| Benchmark | Value | Unit |
|-----------|-------|------|
| Throughput with 1 threads | 12591.500 | req/s |
| Throughput with 4 threads | 36863.000 | req/s |
| Throughput with 8 threads | 36974.500 | req/s |

## Connection Churn

| Benchmark | Value | Unit |
|-----------|-------|------|
| Close-after-each-request throughput (4 threads) | 6134.000 | req/s |

## Scalability

| Benchmark | Value | Unit |
|-----------|-------|------|
| 32 concurrent connections | 42020.400 | req/s |
| 64 concurrent connections | 38892.000 | req/s |
| 128 concurrent connections | 0.000 | req/s |
| 256 concurrent connections | 0.000 | req/s |

## Stability

| Benchmark | Value | Unit |
|-----------|-------|------|
| Sustained throughput | 0.000 | req/s |
| Total requests | 0.000 | requests |

## System Configuration

| Benchmark | Value | Unit |
|-----------|-------|------|
| FD soft limit | 1048576.000 | fds |
| FD hard limit | 1048576.000 | fds |
