# KATANA Framework - Benchmark Results

Generated: 2025-12-26 14:10:48

**Note**: Measurements use time-boxed phases with warm-ups, steady-state sampling, and full response validation.


## Core Performance

| Benchmark | Value | Unit |
|-----------|-------|------|
| Latency samples | 354927.000 | samples |
| Latency avg | 0.045 | ms |
| Latency p50 | 0.033 | ms |
| Latency p90 | 0.074 | ms |
| Latency p95 | 0.092 | ms |
| Latency p99 | 0.149 | ms |
| Latency p999 | 0.311 | ms |
| Latency IQR | 0.021 | ms |
| Latency max | 3.248 | ms |
| Keep-alive throughput | 35541.897 | req/s |
| Keep-alive success | 4996.000 | requests |

## HTTP Parsing

| Benchmark | Value | Unit |
|-----------|-------|------|
| Minimal request samples | 1500.000 | samples |
| Minimal request p50 | 0.024 | ms |
| Minimal request p99 | 0.035 | ms |
| Medium request samples | 1500.000 | samples |
| Medium request p50 | 0.032 | ms |
| Medium request p99 | 0.048 | ms |
| Large headers samples | 1500.000 | samples |
| Large headers p50 | 0.040 | ms |
| Large headers p99 | 0.058 | ms |

## Scalability

| Benchmark | Value | Unit |
|-----------|-------|------|
| Throughput with 1 threads | 36056.000 | req/s |
| Throughput with 4 threads | 118202.000 | req/s |
| Throughput with 8 threads | 178621.000 | req/s |

## Connection Churn

| Benchmark | Value | Unit |
|-----------|-------|------|
| Close-after-each-request throughput (4 threads) | 15758.667 | req/s |

## Scalability

| Benchmark | Value | Unit |
|-----------|-------|------|
| 32 concurrent connections | 189160.000 | req/s |
| 64 concurrent connections | 182770.000 | req/s |
| 128 concurrent connections | 190020.400 | req/s |
| 256 concurrent connections | 192534.000 | req/s |

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
