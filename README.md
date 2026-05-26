# Nokia BGP Prefix SID Lab

A multi-domain Nokia SROS/SR Linux containerized lab demonstrating BGP Prefix SID (Segment Routing) across three network domains. Built with [ContainerLab](https://containerlab.dev/).

![Topology](Topology.png)

## Overview

This lab implements **Seamless MPLS** using BGP Prefix SID (RFC 8669) to distribute segment routing labels across domain boundaries. Key features:

- **BGP-LU (Labeled Unicast)** for inter-domain label distribution
- **ISIS-SR** within each domain as the SR-capable IGP
- **Flexible Algorithm 128** enabled across all domains including SR Linux
- **EVPN** and **VPNv4/v6** services riding the MPLS transport
- **gNMI telemetry** with Prometheus and Grafana for real-time monitoring

## Prerequisites

- [ContainerLab](https://containerlab.dev/) 0.50.0+
- Docker Engine 20.10+
- 32GB RAM minimum (64GB recommended)
- Nokia SROS simulator license: `../license-srsim25.txt`
- Nokia SR Linux license: `../license-srl25.10.txt`

License files must be present one directory above the repo root before deploying.

## Getting Started

```bash
# Deploy the full topology
sudo containerlab deploy -t topo.clab.yml

# Check status of all containers
sudo containerlab inspect -t topo.clab.yml

# Destroy the lab when done
sudo containerlab destroy -t topo.clab.yml
```

## Network Topology

![Lab_Topology](topology_clab.png)

The lab has three domains connected in a chain:

### Domain 1 — Access Ring 1 (Nokia IXR)

| Node | Type | SSH Port | gNMI Port |
|------|------|----------|-----------|
| R01-IXR | IXR-R6 | 50101 | 50102 |
| R02-IXR | IXR-e2 | 50201 | 50202 |
| R03-IXR | IXR-R6 | 50301 | 50302 |
| R04-IXR | IXR-R6 | 50401 | 50402 |

Connected testers: tester1 (192.168.0.1), tester2 (192.168.0.2), tester3 (192.168.0.3), tester4 (192.168.0.4), tester5 (192.168.0.5)

### Domain 2 — Core SR-MPLS (Nokia SR-1 + SR Linux)

| Node | Type | Role | SSH Port | gNMI Port |
|------|------|------|----------|-----------|
| R05-SR | SR-1 | ABR (Domain 1 ↔ Core) | 50501 | 50502 |
| R06-SR | SR-1 | ASBR | 50601 | 50602 |
| R07-SR | SR-1 | Core | 50701 | 50702 |
| R08-SR | SR-1 | Core | 50801 | 50802 |
| R09-SR | SR-1 | Core | 50901 | 50902 |
| R10-SR | SR-1 | Core | 51001 | 51002 |
| R11-SR | SR-1 | ASBR | 51101 | 51102 |
| R12-SXR | SXR-1d-32d (SR Linux) | Multi-NOS interop | 51201 | 51202 |

Connected testers: tester5 (192.168.20.5), tester11 (192.168.0.11)

### Domain 3 — Access Ring 2 (Nokia IXR)

| Node | Type | SSH Port | gNMI Port |
|------|------|----------|-----------|
| R13-IXR | IXR-R6d | 51301 | 51302 |
| R14-IXR | IXR-e2 | 51401 | 51402 |
| R15-IXR | IXR-R6d | 51501 | 51502 |
| R16-IXR | IXR-e2 | 51601 | 51602 |

Connected testers: tester13 (192.168.0.13), tester14 (192.168.0.14), tester16 (192.168.0.16)

## Accessing Devices

```bash
# SSH to a router (default credentials: admin / admin)
ssh admin@R01-IXR   # R01-IXR
ssh admin@R05-SR   # R05-SR (ABR)
ssh admin@R12-SXR # R12-SXR (SR Linux)

# Run commands on tester containers
docker exec -it tester1 ping 192.168.0.2
docker exec -it tester1 ping 192.168.0.16
```

## Validation

On any SROS router:

```
show router bgp summary
show router bgp routes
show router mpls-labels
show router segment-routing prefix-sid
show router isis segment-routing
show router isis database
```

## Configuration Management

Device configurations are stored in two places:

- `startup_config/*.partial.txt` — loaded by ContainerLab on deploy
- `config/*.cfg` / `config/*.json` — full running configs (updated by `save_config.sh`)

To back up current running configs from all containers:

```bash
./save_config.sh
```

## Observability Stack

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:3000 | admin / admin |
| Prometheus | http://localhost:9090 | — |
| Consul | http://localhost:8500 | — |

gNMI (port 57400) streams telemetry from all nodes every 10 seconds. Consul handles dynamic service discovery for Prometheus scrape targets.

## References

- [ContainerLab Documentation](https://containerlab.dev/)
- [Nokia SROS Documentation](https://documentation.nokia.com/)
- RFC 8669 — BGP Prefix Segment Identifiers
