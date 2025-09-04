# BGP Prefix SID Lab - Comprehensive Documentation

## Overview

This is a comprehensive Nokia SROS lab environment designed to demonstrate and validate BGP Prefix SID (Segment Routing) functionality across multiple network domains. The lab showcases advanced MPLS-SR features including BGP-LU (Labeled Unicast), EVPN, VPNv4/v6, and telemetry monitoring.

## Lab Architecture

### Network Topology
The lab consists of a multi-domain network with the following components:

#### Access Ring 1 (Domain 1)
- **R01-IXR**: IXR-R6 chassis with 10G/100G interfaces
- **R02-IXR**: IXR-e2 compact router
- **R03-IXR**: IXR-R6 chassis with 10G/100G interfaces  
- **R04-IXR**: IXR-R6 chassis with 10G/100G interfaces

#### Core Network (Domain 2)
- **R05-SR**: SR-1 chassis (ABR - Area Border Router)
- **R06-SR**: SR-1 chassis
- **R07-SR**: SR-1 chassis
- **R08-SR**: SR-1 chassis
- **R09-SR**: SR-1 chassis
- **R10-SR**: SR-1 chassis
- **R11-SR**: SR-1 chassis
- **R12-SXR**: SR Linux (SXR) - mixed NOS testing

#### Access Ring 2 (Domain 3)
- **R13-IXR**: IXR-R6d compact router
- **R14-IXR**: IXR-e2 compact router
- **R15-IXR**: IXR-R6d compact router
- **R16-IXR**: IXR-e2 compact router

#### Test Endpoints
- **tester1-tester16**: Linux containers for traffic testing and validation
- **gnmic**: gNMI collector for telemetry data
- **consul-agent**: Service discovery and configuration management
- **prometheus**: Metrics collection and storage
- **grafana**: Visualization and monitoring dashboards

## Key Features

### BGP Prefix SID Implementation
- **BGP-LU (Labeled Unicast)**: Enables MPLS label distribution via BGP
- **Prefix SID**: Assigns MPLS labels to network prefixes for SR path control
- **Multi-domain support**: Demonstrates SR across different administrative domains
- **Label Index TLV Flags**: Validates BGP Prefix SID flag implementations

### Network Services
- **EVPN**: Ethernet VPN for Layer 2 services
- **VPNv4/v6**: IP VPN services with MPLS encapsulation
- **ISIS-SR**: Internal Gateway Protocol with Segment Routing
- **MPLS Transport**: End-to-end MPLS path establishment

### Monitoring & Telemetry
- **gNMI**: OpenConfig-based network management
- **Prometheus**: Time-series metrics collection
- **Grafana**: Network monitoring dashboards
- **Consul**: Service discovery and health monitoring

## Prerequisites

### System Requirements
- **Containerlab**: Latest version (recommended 0.50.0+)
- **Docker**: Docker Engine 20.10+
- **Memory**: Minimum 32GB RAM (64GB recommended)
- **Storage**: 50GB+ available disk space
- **CPU**: 8+ cores recommended

### Nokia Licenses
- **SROS 24.10.R1**: Valid Nokia SROS license file
- **SR Linux 24.10.2**: Valid SR Linux license file
- **License files**: Place in project root directory

## Installation & Deployment

### 1. Clone the Repository
```bash
git clone <repository-url>
cd bgp_prefixsid
```

### 2. License Setup
Ensure Nokia license files are in the correct location:
```bash
# Copy your Nokia licenses to the project root
cp /path/to/your/license-sros24.txt ./
cp /path/to/your/license-srl24.10.txt ./
```

### 3. Deploy the Lab
```bash
# Deploy the entire topology
sudo containerlab deploy -t topo.clab.yml

# Verify deployment status
sudo containerlab inspect -t topo.clab.yml
```

### 4. Access Network Devices
```bash
# SSH to routers (example for R01-IXR)
ssh admin@localhost -p 50101

# Default credentials
# Username: admin
# Password: admin
```

## Configuration Management

### Startup Configurations
All routers are pre-configured with startup configurations located in the `config/` directory:
- **SROS devices**: `.cfg` files with Nokia SROS CLI configuration
- **SR Linux**: `.json` files with SR Linux configuration

### Configuration Backup
Use the provided script to backup current configurations:
```bash
# Make script executable
chmod +x save_config.sh

# Run backup
./save_config.sh
```

### Configuration Structure
- **Access routers**: Basic routing, BGP, and interface configuration
- **Core routers**: Advanced SR-ISIS, BGP-LU, and MPLS configuration
- **ABR routers**: Policy-based routing and domain interconnection

## Testing & Validation

### Connectivity Testing
```bash
# Test basic connectivity from tester containers
docker exec -it bgpprefixsid-tester1 ping 192.168.0.2
docker exec -it bgpprefixsid-tester1 ping 192.168.0.3
```

### BGP Prefix SID Validation
1. **Check BGP sessions**:
   ```bash
   # On any SROS router
   show router bgp summary
   show router bgp routes
   ```

2. **Verify Prefix SID labels**:
   ```bash
   # Check MPLS label bindings
   show router mpls-labels
   show router segment-routing prefix-sid
   ```

3. **Validate SR paths**:
   ```bash
   # Check ISIS-SR database
   show router isis database
   show router isis segment-routing
   ```

### Traffic Flow Testing
- **End-to-end connectivity**: Test between different access domains
- **MPLS path validation**: Verify label switching across core network
- **BGP-LU validation**: Confirm labeled route distribution

## Monitoring & Observability

### Access Points
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Consul**: http://localhost:8500

### Key Metrics
- **BGP session status**: Monitor BGP neighbor states
- **MPLS label usage**: Track label allocation and utilization
- **Interface statistics**: Monitor link performance and errors
- **SR path metrics**: Validate segment routing path efficiency

### Telemetry Configuration
- **gNMI subscriptions**: Configured for real-time data collection
- **Prometheus targets**: Pre-configured for all network devices
- **Grafana dashboards**: Pre-built for BGP and MPLS monitoring

## Troubleshooting

### Common Issues

#### Lab Deployment Problems
```bash
# Check container status
sudo containerlab inspect -t topo.clab.yml

# View container logs
sudo containerlab logs -t topo.clab.yml

# Restart specific containers
sudo containerlab restart -t topo.clab.yml --nodes R01-IXR
```

#### BGP Session Issues
```bash
# Check BGP configuration
show router bgp summary
show router bgp neighbor <ip> detail

# Verify routing policies
show router policy-options
```

#### MPLS/SR Problems
```bash
# Check MPLS configuration
show router mpls interface
show router mpls-labels

# Validate SR configuration
show router segment-routing
show router isis segment-routing
```

### Debug Commands
```bash
# Enable debug logging
debug router bgp update
debug router mpls
debug router isis

# Monitor real-time logs
show log log-id 99
```

## Lab Scenarios

### Scenario 1: Basic BGP Prefix SID
- Deploy lab with default configuration
- Validate BGP sessions establishment
- Verify MPLS label distribution

### Scenario 2: Multi-domain SR
- Test end-to-end connectivity across domains
- Validate label switching in core network
- Monitor path optimization

### Scenario 3: Policy-based Routing
- Modify routing policies
- Test different label allocation strategies
- Validate BGP-LU behavior

### Scenario 4: Telemetry Integration
- Enable gNMI subscriptions
- Configure custom monitoring dashboards
- Analyze network performance metrics

## Advanced Features

### Custom Topology Modifications
- **Add new routers**: Extend the topology file
- **Modify interfaces**: Adjust port mappings and VLANs
- **Custom policies**: Implement specific routing requirements

### Integration with External Tools
- **Ansible**: Automate configuration deployment
- **Terraform**: Infrastructure as code management
- **Python scripts**: Custom automation and testing

## Contributing

### Development Guidelines
1. **Configuration changes**: Update both topology and config files
2. **Testing**: Validate changes in lab environment before committing
3. **Documentation**: Update relevant documentation sections
4. **Backup**: Always backup configurations before major changes

### Testing New Features
1. **Isolated testing**: Test new features in separate lab environment
2. **Validation**: Ensure compatibility with existing configurations
3. **Documentation**: Document new features and configuration steps

## Support & Resources

### Documentation
- **Nokia SROS**: [Nokia Documentation](https://documentation.nokia.com/)
- **Containerlab**: [Containerlab Documentation](https://containerlab.dev/)
- **BGP Prefix SID**: RFC 8669 and related standards

### Community
- **Nokia Community**: [Nokia Community Forum](https://community.nokia.com/)
- **Containerlab**: [GitHub Discussions](https://github.com/srl-labs/containerlab/discussions)

### License Information
This lab uses Nokia SROS and SR Linux software. Ensure you have valid licenses for production use.

## Version History

- **v1.0**: Initial lab setup with basic BGP Prefix SID
- **v1.1**: Added telemetry and monitoring components
- **v1.2**: Enhanced multi-domain support and testing tools
- **v1.3**: Current version with comprehensive monitoring and validation

---

**Note**: This lab is designed for educational and testing purposes. Always validate configurations in a safe environment before applying to production networks.
