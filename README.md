# Sentinel Lab — Prometheus Monitoring and Alerting

## Overview

This project provides lightweight monitoring for the Sentinel Lab using Prometheus, Node Exporter, and Blackbox Exporter. It collects Linux host metrics, probes the application's HTTP health endpoint, and evaluates alert rules.

## Architecture

- **Prometheus:** Scrapes metrics, evaluates alert rules, and stores time-series data.
- **Node Exporter:** Exposes Linux host CPU, memory, filesystem, and network metrics.
- **Blackbox Exporter:** Probes the application's HTTP health endpoint.
- **Application:** Exposes `http://127.0.0.1:8080/health` on the Ubuntu VM.

## Ports

| Service | Port | Purpose |
|---|---:|---|
| Prometheus | 9090 | Queries, targets, and alerts |
| Blackbox Exporter | 9115 | HTTP probing |
| Node Exporter | 9100 | Linux host metrics |
| Application | 8080 | Health endpoint |

## Prerequisites

- Ubuntu Linux VM with Docker Engine and Docker Compose
- Application container named `sentinel-app`, exposing host port `8080`
- Node Exporter reachable on host port `9100`
- Repository configuration files in their documented layout

The Compose configuration uses Docker's `host-gateway` mapping to let the exporters reach services on the host.

## Configuration

- Scrape interval: `15s`
- Rule evaluation interval: `15s`
- Data retention: `48h`
- Persistent named volume: `prometheus-data`
- Configuration files are mounted read-only.
- Monitoring containers use `restart: unless-stopped`.

## Deployment

For a fresh deployment, clone this repository on the Ubuntu VM and run the commands from the repository root:

```bash
git clone https://github.com/atefehsaeedian/Sentinel-Lab.git
cd Sentinel-Lab
sudo docker compose -f compose/compose.yaml config -q
sudo docker compose -f compose/compose.yaml up -d
sudo docker compose -f compose/compose.yaml ps
```

Do not start a second copy of this stack while containers with the same configured names are already running. The existing lab deployment is managed separately from the repository checkout.

Check Prometheus targets:

```bash
curl -s http://127.0.0.1:9090/api/v1/targets
```

Open the Prometheus interface at `http://127.0.0.1:9090`.

## Example PromQL Queries

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

### Application health probe

```promql
probe_success{job="app-health"}
```

A value of `1` indicates success; `0` indicates failure.

## Alert Rules

Rules are defined in `prometheus/alert-rules.yml`.

| Alert | Condition | Pending duration |
|---|---|---|
| `InstanceDown` | A scrape target is down | 1 minute |
| `HighCPUUsage` | CPU usage exceeds 80% | 5 minutes |
| `LowDiskSpace` | Available root filesystem space is below 15% | 2 minutes |
| `HttpHealthFailed` | The application HTTP probe fails | 1 minute |

## Test the HTTP Health Alert

**Warning:** This test briefly interrupts the test application.

Stop the application:

```bash
sudo docker stop sentinel-app
```

Wait at least 75 seconds and inspect alerts:

```bash
curl -s http://127.0.0.1:9090/api/v1/alerts
```

The `HttpHealthFailed` alert should fire if the endpoint remains unavailable long enough.

Restore the application immediately:

```bash
sudo docker start sentinel-app
curl -i http://127.0.0.1:8080/health
```

The endpoint should return HTTP `200`. After Prometheus reevaluates the probe, the alert should no longer remain active.

## Persistence and Operations

- Prometheus data is stored in the `prometheus-data` named volume.
- The retention period is `48h`.
- Monitoring containers restart automatically unless explicitly stopped.
- The application and Node Exporter are managed outside this Compose stack.

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

This stack provides host metrics, HTTP probing, and Prometheus alert evaluation. Alertmanager delivery to Telegram or a webhook is not configured. Do not commit credentials, API tokens, or other secrets.
