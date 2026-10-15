# Sentinel Lab — Infrastructure Monitoring

## Overview

Sentinel Lab is a hands-on infrastructure monitoring project designed to provide visibility into application health, host resources, network activity, and service availability.

The project uses Prometheus to collect and evaluate metrics, Node Exporter to expose host-level metrics, Blackbox Exporter to probe application endpoints, and Grafana to visualize monitoring data through a centralized NOC dashboard.

The environment is designed to support future extensions, including alerting, security monitoring, infrastructure automation, and automated remediation.

## Architecture

### Monitoring Components

- **Prometheus:** Collects and stores time-series metrics and evaluates alerting rules.
- **Node Exporter:** Exposes host-level metrics, including CPU, memory, disk, and network statistics.
- **Blackbox Exporter:** Performs HTTP probes to monitor endpoint availability and response behavior.
- **Grafana:** Visualizes monitoring data through dashboards for infrastructure and application health.
- **Application:** A containerized service monitored through its HTTP health endpoint.

### Ports

| Component | Port | Purpose |
|---|---:|---|
| Application | 8080 | Application HTTP endpoint |
| Prometheus | 9090 | Metrics, queries, and targets |
| Node Exporter | 9100 | Host metrics |
| Blackbox Exporter | 9115 | HTTP probing metrics |
| Grafana | 3000 | Monitoring dashboards |

Ports are exposed within the lab environment according to the configured Docker and networking setup.

## Prometheus Configuration

Prometheus is configured to collect metrics from the following targets:

- Application health endpoint through Blackbox Exporter probing.
- Blackbox Exporter metrics.
- Node Exporter host metrics.
- Prometheus self-monitoring endpoint.

The Prometheus configuration and alert rules are maintained as files in the repository.

### Data Retention

Prometheus is configured to retain metrics for 48 hours.

### Useful PromQL Queries

**Target availability**

```promql
up
```

**Application HTTP probe status**

```promql
probe_success
```

**CPU usage percentage**

```promql
100 * (1 - avg by (instance) (
  rate(node_cpu_seconds_total{mode="idle"}[5m])
))
```

**Memory usage percentage**

```promql
100 * (1 -
  node_memory_MemAvailable_bytes /
  node_memory_MemTotal_bytes
)
```

**Root filesystem available space in bytes**

```promql
node_filesystem_avail_bytes{mountpoint="/", fstype!=""}
```

**Network receive rate**

```promql
rate(node_network_receive_bytes_total{device!~"lo|docker.*|veth.*"}[5m])
```

**Network transmit rate**

```promql
rate(node_network_transmit_bytes_total{device!~"lo|docker.*|veth.*"}[5m])
```

## Alerting Rules

The repository includes alert rules for monitoring important infrastructure and application conditions:

- Target availability.
- Application HTTP health.
- High CPU utilization.
- Low available memory.

Alert rules are maintained in `prometheus/alert-rules.yml` and loaded through the Prometheus configuration.

Alert delivery through Alertmanager is not currently configured.

## Grafana NOC Dashboard

### Dashboard Overview

The **Sentinel NOC Overview** dashboard provides a centralized view of application availability and host resource utilization.

Grafana uses Prometheus as its data source.

The dashboard is available in the repository as an exported JSON file:

`grafana/dashboards/sentinel-noc-overview.json`

### Monitoring Panels

The dashboard includes the following panels:

- **Host Availability:** Displays whether the monitored host is available.
- **Application HTTP Health:** Shows the application health probe status.
- **CPU Usage:** Displays host CPU utilization.
- **Memory Usage:** Displays host memory utilization.
- **Root Disk Available:** Shows available space on the root filesystem.
- **Network Receive Rate:** Displays incoming network traffic rate.
- **Network Transmit Rate:** Displays outgoing network traffic rate.
- **HTTP Probe History:** Visualizes application probe results over time.
- **Target Health Table:** Provides a tabular overview of monitoring target status.

The dashboard includes Stat, Time series, and Table visualizations, with appropriate units, descriptions, and thresholds where applicable.

### Dashboard Variables and Time Ranges

An `Instance` variable allows filtering by the monitored instance. The current environment contains one configured Node Exporter instance, so the available choices are `All` and the configured instance.

The dashboard has been tested with both of the following time ranges:

- Last 15 minutes.
- Last 1 hour.

The dashboard refresh interval is configured to 15 seconds.

Additional instances can be displayed by configuring additional Prometheus targets and ensuring their metrics are available.

## Application Outage and Recovery Validation

The monitoring setup has been tested by stopping and restarting the application container.

### Test Procedure

1. Stop the application container:

   ```bash
   sudo docker stop sentinel-app
   ```

2. Allow Prometheus to collect subsequent probe results.
3. Verify that **Application HTTP Health** changes from `1` to `0`.
4. Verify that **HTTP Probe History** records the outage.
5. Verify that **Host Availability** remains `1` while the host continues running.
6. Restore the application container:

   ```bash
   sudo docker start sentinel-app
   ```

7. Verify that application health returns to `1`.

### Validation Result

**Passed.** The dashboard detected the application outage and showed recovery after the application container was restarted.

This test confirms that application availability can be monitored independently of host availability.

## Repository Structure

```text
Sentinel-Lab/
├── blackbox/
│   └── blackbox.yml
├── compose/
│   └── compose.yaml
├── grafana/
│   └── dashboards/
│       └── sentinel-noc-overview.json
├── prometheus/
│   ├── prometheus.yml
│   └── alert-rules.yml
└── README.md
```

## Validation

The Docker Compose configuration can be validated with:

```bash
docker compose -f compose/compose.yaml config -q
```

The exported Grafana dashboard JSON can be validated with:

```bash
python3 -m json.tool grafana/dashboards/sentinel-noc-overview.json >/dev/null
```

## Current Scope and Future Improvements

The current implementation provides application health monitoring, host metrics, HTTP probing, alert-rule definitions, and a Grafana dashboard.

Potential future improvements include:

- Configuring Alertmanager and notification channels.
- Adding more monitored hosts and application instances.
- Extending security monitoring and log collection.
- Implementing infrastructure automation and auto-remediation.
- Expanding dashboard coverage as the lab evolves.

## Deployment Topology

Sentinel Lab runs in a local virtualized environment. The macOS host runs VirtualBox and provides access to the Ubuntu virtual machine through SSH port forwarding. Docker containers and monitoring services run inside the Ubuntu VM unless otherwise specified.

### Logical Architecture

```text
                         macOS Host
                    (MacBook Pro / VirtualBox)
                              |
                    SSH Port Forwarding
                         Port 2222
                              |
                              v
                     Ubuntu Virtual Machine
                              |
                +-------------+-------------+
                |             |             |
                v             v             v
        Application      Prometheus      Grafana
        Container        Container       Container
        Port 8000        Port 9090       Port 3000
                |             ^
                |             |
                v             |
          /health endpoint    |
                |             |
                v             |
        Blackbox Exporter ----+
             Port 9115
                              ^
                              |
                       Node Exporter
                         Port 9100
```

### Service Placement and Connectivity

- **macOS host:** Runs VirtualBox and provides SSH access to the Ubuntu VM through host port `2222`.
- **Ubuntu VM:** Hosts the application container, Prometheus, Blackbox Exporter, Grafana, and Node Exporter.
- **Application container:** Listens on container port `8000`, exposed as port `8080` on the Ubuntu VM. Its `/health` endpoint is monitored by Blackbox Exporter.
- **Prometheus:** Runs on port `9090` and scrapes the configured monitoring targets, including Blackbox Exporter, Node Exporter, and its own metrics endpoint.
- **Blackbox Exporter:** Runs on port `9115` and performs HTTP probes against the application health endpoint.
- **Node Exporter:** Runs on the Ubuntu VM and exposes host-level CPU, memory, disk, and network metrics on port `9100`.
- **Grafana:** Runs on port `3000` and queries Prometheus to display the Sentinel NOC Overview dashboard.

### Access from the macOS Host

The Ubuntu VM is accessed through SSH port forwarding:

```bash
ssh -p 2222 devops@127.0.0.1
```

To access Grafana through an SSH tunnel, run the following command in a separate macOS terminal and leave it running:

```bash
ssh -N -L 3000:127.0.0.1:3000 -p 2222 devops@127.0.0.1
```

Then open `http://localhost:3000` in a browser on the macOS host.

Prometheus is available through the corresponding local port forwarding or the VM's configured network access.

### Network and Deployment Notes

- Container-to-container communication uses the configured Docker network.
- Prometheus reaches the application health endpoint and Node Exporter through the configured host-access addresses.
- The Grafana data source uses `http://host.docker.internal:9090` in the current configuration.
- Host port mappings and firewall rules determine which services are reachable from outside the VM.
- This diagram describes the current logical topology; it does not imply that every service port is publicly exposed.
