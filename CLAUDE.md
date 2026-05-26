# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A Nokia SROS/SR Linux containerized network lab demonstrating BGP Prefix SID (Segment Routing) across three multi-domain networks. Built with [ContainerLab](https://containerlab.dev/). No traditional software build system — the "code" is network device configuration and topology definitions.

## Lab Lifecycle Commands

```bash
# Deploy the full topology
sudo containerlab deploy -t topo.clab.yml

# Check status of all containers
sudo containerlab inspect -t topo.clab.yml

# View logs
sudo containerlab logs -t topo.clab.yml

# Restart a specific node
sudo containerlab restart -t topo.clab.yml --nodes R01-IXR

# Destroy the lab
sudo containerlab destroy -t topo.clab.yml
```

## Accessing Devices

```bash
# SSH to routers: ports follow the pattern 501XX (e.g., R01 → 50101, R05 → 50105)
ssh admin@localhost -p 50101   # R01-IXR
# Default credentials: admin / admin

# Access tester containers
docker exec -it bgpprefixsid-tester1 ping 192.168.0.2
```

## Configuration Backup

```bash
./save_config.sh
```

This copies running configs from containerlab container tftpboot dirs into `config/`. Always run this after making device changes you want to persist.

## Architecture

### Three-Domain Topology

| Domain | Nodes | Role |
|--------|-------|------|
| Access Ring 1 | R01–R04 (IXR) | Edge routers, testers 1–5 |
| Core | R05–R12 (SR/SXR) | MPLS backbone; R05 is ABR; R12 is SR Linux |
| Access Ring 2 | R13–R16 (IXR) | Edge routers, testers 13–16 |

- **R05-SR** is the Area Border Router (ABR) connecting Access Ring 1 to the Core.
- **R12-SXR** is the only Nokia SR Linux node — used for multi-NOS interoperability testing.
- **R06-SR** functions as the ASBR for inter-domain routing.

### Config File Locations

| Directory | Contents |
|-----------|----------|
| `config/` | Full running configs (`.cfg` for SROS, `.json` for SR Linux) — source of truth after `save_config.sh` |
| `startup_config/` | Partial bootstrap configs loaded by ContainerLab on deploy (`*.partial.txt`) |
| `topo.clab.yml` | Topology definition: node types, image versions, port mappings, license paths |
| `tele-config/` | gNMI collector (`gnmic.yaml`), Prometheus (`prometheus/`), Grafana (`grafana/`) |

### Routing Stack

- **ISIS-SR** within each domain (segment routing IGP)
- **BGP-LU** (Labeled Unicast) for inter-domain label distribution
- **BGP Prefix SID** (RFC 8669): assigns MPLS labels to prefixes for SR path control
- **Flex Algo 128**: currently active — enabled across all domains including SR Linux (recent commits)
- **EVPN** and **VPNv4/v6** for services riding the MPLS transport

### MPLS Label Ranges

- `100000–101000`: SR labels
- `101001–102000`: EVPN BUM labels

### Observability Stack

| Service | URL |
|---------|-----|
| Grafana | http://localhost:3000 (admin/admin) |
| Prometheus | http://localhost:9090 |
| Consul | http://localhost:8500 |

gNMI streams metrics every 10 seconds; Consul handles dynamic service discovery for Prometheus scrape targets.

## Validation Commands (on SROS devices)

```
show router bgp summary
show router bgp routes
show router mpls-labels
show router segment-routing prefix-sid
show router isis database
show router isis segment-routing
show log log-id 99
```

## Key Notes

- License files (`license-sros*.txt`, `license-srl*.txt`) must be present in the project root before deploying — they are referenced in `topo.clab.yml` but not committed to git.
- The `clab-bgpprefixsid/` directory is the ContainerLab runtime directory (auto-generated, ~200MB). Do not edit files there directly.
- SROS device configs use Nokia MD-CLI format. SR Linux uses JSON (gNMI/YANG-based).
- The active development branch is `srl_abr`; recent work focused on Flex Algo 128 propagation across all domains.
