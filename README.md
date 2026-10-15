# Sentinel Lab — Prometheus Monitoring and Alerting

## Overview

This project implements a lightweight monitoring stack for the Sentinel Lab using Prometheus and Blackbox Exporter. It monitors host-level system metrics and checks the application's HTTP health endpoint.

## Architecture

- **Prometheus** collects metrics, evaluates alert rules, and stores time-series data.
- **Node Exporter** exposes Linux host metrics.
- **Blackbox Exporter** probes the application's HTTP health endpoint.
- **Application** exposes its health endpoint at `http://127.0.0.1:8080/health` on the Ubuntu VM.

### Ports

| Service | Port | Purpose |
|---|---:|---|
| Prometheus | 9090 | Metrics, queries, and alerts |
| Blackbox Exporter | 9115 | HTTP probing |
| Node Exporter | 9100 | Linux host metrics |
| Application | 8080 | Application health endpoint |

## Prerequisites

- Ubuntu Linux VM with Docker Engine and Docker Compose
- A running application container exposing port `8080`
- Node Exporter running on host port `9100`
- The repository's `prometheus/`, `blackbox/`, and `compose/` configuration files

The Compose configuration uses `host.docker.internal` with Docker's `host-gateway` mapping to reach services running on the host.

## Configuration

- Prometheus scrape interval: `15s`
- Rule evaluation interval: `15s`
- Prometheus data retention: `48h`
- Prometheus data is stored in the named Docker volume `prometheus-data`.
- Configuration files are mounted read-only into their containers.

## Start the Monitoring Stack

Run these commands from the repository root on the Ubuntu VM:

```bash
cd ~/Sentinel-Lab
sudo docker compose -f compose/compose.yaml up -d
sudo docker compose -f compose/compose.yaml ps
```

Check Prometheus targets:

```bash
curl -s http://127.0.0.1:9090/api/v1/targets
```

Open the Prometheus web interface at `http://127.0.0.1:9090`.

## Monitored Metrics

Examples of useful PromQL queries:

### Target availability

```promql
up
```

### Available memory in bytes

```promql
node_memory_MemAvailable_bytes
```

### CPU usage percentage

```promql
100 * (1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])))
```

### Available root filesystem percentage

```promql
100 * node_filesystem_avail_bytes{mountpoint="/",fstype!~"tmpfs|overlay"} / node_filesystem_size_bytes{mountpoint="/",fstype!~"tmpfs|overlay"}
```

### Application HTTP probe result

```promql
probe_success{job="app-health"}
```

A value of `1` indicates a successful probe; `0` indicates failure.

## Alert Rules

The following alert rules are configured in `prometheus/alert-rules.yml`:

| Alert | Condition | Pending duration |
|---|---|---|
| `InstanceDown` | A scrape target is down | 1 minute |
| `HighCPUUsage` | CPU usage exceeds 80% | 5 minutes |
| `LowDiskSpace` | Available root filesystem space is below 15% | 2 minutes |
| `HttpHealthFailed` | Application HTTP probe fails | 1 minute |

## Test Application Health Alert

**Warning:** The following test deliberately stops the test application container. Run it only when a brief interruption is acceptable.

Stop the application:

```bash
sudo docker stop sentinel-app
```

Wait at least 75 seconds, then inspect active alerts:

```bash
curl -s http://127.0.0.1:9090/api/v1/alerts
```

The `HttpHealthFailed` alert should become firing if the endpoint remains unavailable long enough.

Restore the application immediately after the test:

```bash
sudo docker start sentinel-app
curl -i http://127.0.0.1:8080/health
```

The health endpoint should return HTTP `200` when the application is healthy again. After Prometheus reevaluates the probe, the alert should no longer remain active.

## Persistence and Restart Behavior

- The Prometheus time-series database uses the named Docker volume `prometheus-data`.
- Both monitoring containers use `restart: unless-stopped`.
- The retention period is configured to `48h`.
- The application and Node Exporter are prerequisites external to this Compose stack.

## Configuration Layout

```text
Sentinel-Lab/
├── blackbox/
│   └── blackbox.yml
├── compose/
│   └── compose.yaml
├── prometheus/
│   ├── alert-rules.yml
│   └── prometheus.yml
└── README.md
```

## Scope and Limitations

This configuration provides metrics collection, HTTP health probing, and Prometheus alert evaluation. Alertmanager notification delivery (such as Telegram or webhook notifications) is not configured in this stack.

