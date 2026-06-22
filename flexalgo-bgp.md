
# Flex Algo configuration for service

Configuration below is just in one direction where ingress PE is R05 and egress PE is R16. 
It requires configuration in the opposite direction for traffic to flow properly.

## Option 1: Separate loopback

This solution requires a separate loopback interface per flex algo/

### 1. Egress PE

Create an additional loopback for flex algo and advertise with via ISIS with its own node SID.
See `interface "flexalgo128"` below.

```
(gl)[/configure router "Base"]
A:admin@R16-IXR# info flat 
    apply-groups ["NETWORK-INTERFACE"]
    autonomous-system 65000
    interface "flexalgo128" loopback
    interface "flexalgo128" ipv4 primary address 16.16.16.16
    interface "flexalgo128" ipv4 primary prefix-length 32
    interface "system" ipv4 primary address 10.0.20.16
    interface "system" ipv4 primary prefix-length 32
    interface "toR15" port 1/1/c1/1
    interface "toR15" if-attribute delay static 1000
    mpls-labels sr-labels start 100000
    mpls-labels sr-labels end 101000
    mpls-labels reserved-label-block "evpn-bum-label" start-label 101001
    mpls-labels reserved-label-block "evpn-bum-label" end-label 102000
    bgp admin-state enable
    bgp rapid-withdrawal true
    bgp rapid-update vpn-ipv4 true
    bgp rapid-update vpn-ipv6 true
    bgp rapid-update evpn true
    bgp next-hop-resolution labeled-routes transport-tunnel family label-ipv4 resolution any
    bgp rib-management label-ipv4 route-table-import policy-name "export-label-system"
    bgp segment-routing admin-state enable
    bgp segment-routing prefix-sid-range global
    bgp group "access" next-hop-self true
    bgp group "access" peer-as 65000
    bgp group "access" family vpn-ipv4 true
    bgp group "access" family vpn-ipv6 true
    bgp group "access" family evpn true
    bgp group "access" family label-ipv4 true
    bgp group "access" export policy ["export-label-system"]
    bgp neighbor "10.0.0.11" group "access"
    bgp neighbor "10.0.0.12" group "access"
    isis 1 admin-state enable
    isis 1 advertise-router-capability as
    isis 1 ipv6-routing native
    isis 1 level-capability 1
    isis 1 standard-multi-instance true
    isis 1 traffic-engineering true
    isis 1 area-address [49.1022.2222]
    isis 1 multi-topology ipv6-unicast true
    isis 1 { loopfree-alternate remote-lfa }
    isis 1 { loopfree-alternate ti-lfa }
    isis 1 flexible-algorithms admin-state enable
    isis 1 flexible-algorithms flex-algo 128 participate true
    isis 1 { flexible-algorithms flex-algo 128 loopfree-alternate }
    isis 1 { flexible-algorithms flex-algo 128 micro-loop-avoidance }
    isis 1 traffic-engineering-options application-link-attributes legacy false
    isis 1 segment-routing admin-state enable
    isis 1 segment-routing prefix-sid-range global
    isis 1 interface "flexalgo128" flex-algo 128 ipv4-node-sid index 216
    isis 1 interface "system" interface-type point-to-point
    isis 1 interface "toR15" interface-type point-to-point
    isis 1 level 1 wide-metrics-only true
    mpls admin-state enable
    mpls { interface "system" }
    mpls { interface "toR15" }
    rsvp admin-state disable
    rsvp { interface "system" }
    rsvp { interface "toR15" }
    segment-routing sr-mpls prefix-sids "system" ipv4-sid index 16
```


Configure a policy to export this same loopback (16.16.16.16) via BGP-LU changing its next-hop to its own (16.16.16.16).
```
(gl)[/configure policy-options]
A:admin@R16-IXR# info flat 
    community "access-1" { member "65000:1" }
    community "access-2" { member "65000:2" }
    community "core" { member "65000:0" }
    community "flexalgo128" { member "color:10:100" }
    community "vsi-4000" { member "target:65000:4000" }
    prefix-list "flexalgo128" { prefix 16.16.16.16/32 type exact }
    prefix-list "if-system" { prefix 10.0.20.16/32 type exact }
    policy-statement "export-epipe" default-action action-type accept
    policy-statement "export-epipe" default-action community add ["flexalgo128" "vsi-4000"]
    policy-statement "export-label-system" entry 10 from prefix-list ["if-system"]
    policy-statement "export-label-system" entry 10 from protocol name [direct]
    policy-statement "export-label-system" entry 10 action action-type accept
    policy-statement "export-label-system" entry 10 action community add ["access-2"]
    policy-statement "export-label-system" entry 20 from prefix-list ["flexalgo128"]
    policy-statement "export-label-system" entry 20 from protocol name [direct]
    policy-statement "export-label-system" entry 20 action action-type accept
    policy-statement "export-label-system" entry 20 action next-hop 16.16.16.16
    policy-statement "export-label-system" entry 20 action sr-label-index value 216
    policy-statement "export-label-system" entry 20 action sr-label-index prefer-igp true
```

Change the next hop for the specific service. See `route-next-hop` below.
```
(gl)[/configure service]
A:admin@R16-IXR# info flat 
    epipe "R1-R16" admin-state enable
    epipe "R1-R16" service-id 116
    epipe "R1-R16" customer "1"
    epipe "R1-R16" service-mtu 1514
    epipe "R1-R16" sap 1/1/c2/1:116 ingress vlan-manipulation action translate-1-to-1
    epipe "R1-R16" sap 1/1/c2/1:116 ingress vlan-manipulation outer-tag 116
    epipe "R1-R16" sap 1/1/c2/1:116 ingress vlan-manipulation inner-tag null
    epipe "R1-R16" sap 1/1/c2/1:116 egress vlan-manipulation action preserve
    epipe "R1-R16" bgp-evpn evi 116
    epipe "R1-R16" bgp-evpn local-attachment-circuit "local-ac" eth-tag 161
    epipe "R1-R16" bgp-evpn remote-attachment-circuit "remote-ac" eth-tag 116
    epipe "R1-R16" bgp-evpn mpls 1 admin-state enable
    epipe "R1-R16" bgp-evpn mpls 1 auto-bind-tunnel resolution any
    epipe "R5-R16" admin-state enable
    epipe "R5-R16" service-id 4000
    epipe "R5-R16" customer "1"
    epipe "R5-R16" service-mtu 1514
    epipe "R5-R16" { sap 1/1/c2/1:10 }
    epipe "R5-R16" bgp-evpn evi 4000
    epipe "R5-R16" bgp-evpn local-attachment-circuit "local-ac" eth-tag 165
    epipe "R5-R16" bgp-evpn remote-attachment-circuit "remote-ac" eth-tag 516
    epipe "R5-R16" bgp-evpn mpls 1 admin-state enable
    epipe "R5-R16" bgp-evpn mpls 1 auto-bind-tunnel resolution any
    epipe "R5-R16" bgp-evpn mpls 1 route-next-hop ip-address 16.16.16.16
```

### 2. Inline RR (ABR)

An additional Anycast loopback interface (11.11.11.11) for flex algo 128 that is used as next-hop for the ingress PE flex algo loopback (16.16.16.16).
See `interface "flexalgo128-core"` 

```
(gl)[/configure router "Base"]
A:admin@R11-SR# info flat
    apply-groups ["NETWORK-INTERFACE"]
    autonomous-system 65000
    interface "BGPAnycast-Access" loopback
    interface "BGPAnycast-Access" ipv4 primary address 4.4.4.4
    interface "BGPAnycast-Access" ipv4 primary prefix-length 32
    interface "BGPAnycast-Core" loopback
    interface "BGPAnycast-Core" ipv4 primary address 2.2.2.2
    interface "BGPAnycast-Core" ipv4 primary prefix-length 32
    interface "flexalgo128-core" loopback
    interface "flexalgo128-core" ipv4 primary address 11.11.11.11
    interface "flexalgo128-core" ipv4 primary prefix-length 32
    interface "system" ipv4 primary address 10.0.0.11
    interface "system" ipv4 primary prefix-length 32
    interface "toR09" port 1/1/c1/1
    interface "toR09" if-attribute delay static 1000
    interface "toR12" port 1/1/c2/1
    interface "toR12" if-attribute delay static 1000
    interface "toR13" port 1/1/c3/1
    interface "toR13" if-attribute delay static 1000
    mpls-labels sr-labels start 100000
    mpls-labels sr-labels end 101000
    mpls-labels reserved-label-block "evpn-bum-label" start-label 101001
    mpls-labels reserved-label-block "evpn-bum-label" end-label 102000
    bgp admin-state enable
    bgp advertise-inactive true
    bgp rapid-withdrawal true
    bgp rapid-update vpn-ipv4 true
    bgp rapid-update vpn-ipv6 true
    bgp rapid-update evpn true
    bgp next-hop-resolution labeled-routes transport-tunnel family label-ipv4 resolution any
    bgp segment-routing admin-state enable
    bgp segment-routing prefix-sid-range global
    bgp group "access" next-hop-self true
    bgp group "access" peer-as 65000
    bgp group "access" family vpn-ipv4 true
    bgp group "access" family vpn-ipv6 true
    bgp group "access" family evpn true
    bgp group "access" family label-ipv4 true
    bgp group "access" cluster cluster-id 10.0.0.11
    bgp group "access" import policy ["import-access"]
    bgp group "access" export policy ["export-label-system" "change-NH-access"]
    bgp group "core" next-hop-self true
    bgp group "core" peer-as 65000
    bgp group "core" family vpn-ipv4 true
    bgp group "core" family vpn-ipv6 true
    bgp group "core" family evpn true
    bgp group "core" family label-ipv4 true
    bgp group "core" export policy ["export-label-system" "change-NH"]
    bgp neighbor "10.0.0.7" group "core"
    bgp neighbor "10.0.20.13" group "access"
    bgp neighbor "10.0.20.14" group "access"
    bgp neighbor "10.0.20.15" group "access"
    bgp neighbor "10.0.20.16" group "access"
    isis 0 admin-state enable
    isis 0 advertise-router-capability as
    isis 0 ipv6-routing native
    isis 0 level-capability 2
    isis 0 standard-multi-instance true
    isis 0 traffic-engineering true
    isis 0 area-address [49.1000.0000.00]
    isis 0 multi-topology ipv6-unicast true
    isis 0 { loopfree-alternate remote-lfa }
    isis 0 { loopfree-alternate ti-lfa }
    isis 0 flexible-algorithms admin-state enable
    isis 0 flexible-algorithms flex-algo 128 participate true
    isis 0 { flexible-algorithms flex-algo 128 loopfree-alternate }
    isis 0 { flexible-algorithms flex-algo 128 micro-loop-avoidance }
    isis 0 traffic-engineering-options application-link-attributes legacy false
    isis 0 segment-routing admin-state enable
    isis 0 segment-routing prefix-sid-range global
    isis 0 interface "BGPAnycast-Core" passive true
    isis 0 interface "BGPAnycast-Core" ipv4-node-sid index 100
    isis 0 interface "BGPAnycast-Core" ipv4-node-sid clear-n-flag true
    isis 0 interface "flexalgo128-core" flex-algo 128 ipv4-node-sid index 211
    isis 0 interface "system" interface-type point-to-point
    isis 0 interface "toR09" interface-type point-to-point
    isis 0 interface "toR12" interface-type point-to-point
    isis 0 level 2 wide-metrics-only true
    isis 1 admin-state enable
    isis 1 advertise-router-capability as
    isis 1 ipv6-routing native
    isis 1 level-capability 1
    isis 1 standard-multi-instance true
    isis 1 traffic-engineering true
    isis 1 area-address [49.1022.2222]
    isis 1 multi-topology ipv6-unicast true
    isis 1 { loopfree-alternate remote-lfa }
    isis 1 { loopfree-alternate ti-lfa }
    isis 1 flexible-algorithms admin-state enable
    isis 1 flexible-algorithms flex-algo 128 participate true
    isis 1 flexible-algorithms flex-algo 128 advertise "Flex-Algo-128-2"
    isis 1 { flexible-algorithms flex-algo 128 loopfree-alternate }
    isis 1 { flexible-algorithms flex-algo 128 micro-loop-avoidance }
    isis 1 traffic-engineering-options application-link-attributes legacy false
    isis 1 segment-routing admin-state enable
    isis 1 segment-routing prefix-sid-range global
    isis 1 interface "BGPAnycast-Access" passive true
    isis 1 interface "BGPAnycast-Access" ipv4-node-sid index 200
    isis 1 interface "BGPAnycast-Access" ipv4-node-sid clear-n-flag true
    isis 1 interface "system" interface-type point-to-point
    isis 1 interface "toR12" interface-type point-to-point
    isis 1 interface "toR13" interface-type point-to-point
    isis 1 level 1 wide-metrics-only true
    ldp admin-state enable
    mpls admin-state enable
    mpls { interface "system" }
    mpls { interface "toR09" }
    mpls { interface "toR12" }
    rsvp admin-state disable
    rsvp { interface "system" }
    rsvp { interface "toR09" }
    rsvp { interface "toR12" }
    segment-routing sr-mpls prefix-sids "system" ipv4-sid index 11
```

See `policy-statement "change-NH" ` below.

```
(gl)[/configure policy-options]
A:admin@R11-SR# info flat
    community "access-1" { member "65000:1" }
    community "access-2" { member "65000:2" }
    community "core" { member "65000:0" }
    prefix-list "flexalgo128" { prefix 16.16.16.16/32 type exact }
    prefix-list "if-system" { prefix 10.0.0.11/32 type exact }
    prefix-list "routers-system-ip" { prefix 10.0.0.0/16 type longer }
    policy-statement "change-NH" entry 10 from prefix-list ["routers-system-ip"]
    policy-statement "change-NH" entry 10 from family [label-ipv4]
    policy-statement "change-NH" entry 10 from protocol name [bgp-label]
    policy-statement "change-NH" entry 10 action action-type accept
    policy-statement "change-NH" entry 10 action next-hop 2.2.2.2
    policy-statement "change-NH" entry 10 action sr-label-index value 116
    policy-statement "change-NH" entry 10 action sr-label-index prefer-igp true
    policy-statement "change-NH" entry 20 from prefix-list ["flexalgo128"]
    policy-statement "change-NH" entry 20 from family [label-ipv4]
    policy-statement "change-NH" entry 20 from protocol name [bgp-label]
    policy-statement "change-NH" entry 20 action action-type accept
    policy-statement "change-NH" entry 20 action next-hop 11.11.11.11
    policy-statement "change-NH" entry 20 action sr-label-index value 211
    policy-statement "change-NH" entry 20 action sr-label-index prefer-igp true
    policy-statement "change-NH" default-action action-type reject
    policy-statement "change-NH-access" entry 10 from family [label-ipv4]
    policy-statement "change-NH-access" entry 10 from protocol name [bgp-label]
    policy-statement "change-NH-access" entry 10 action action-type accept
    policy-statement "change-NH-access" entry 10 action next-hop 4.4.4.4
    policy-statement "export-label-system" entry 10 from prefix-list ["if-system"]
    policy-statement "export-label-system" entry 10 from protocol name [direct]
    policy-statement "export-label-system" entry 10 action action-type accept
    policy-statement "export-label-system" entry 10 action community add ["access-2" "core"]
    policy-statement "import-access" entry 10 from prefix-list ["flexalgo128"]
    policy-statement "import-access" entry 10 from family [label-ipv4]
    policy-statement "import-access" entry 10 from protocol name [bgp-label]
    policy-statement "import-access" entry 10 action action-type accept
    policy-statement "import-access" entry 10 action flex-algo 128
    policy-statement "routers-system" entry 10 from prefix-list ["routers-system-ip"]
    policy-statement "routers-system" entry 10 action action-type accept
```

### 3. Ingress PE

No changes

```
(gl)[/configure service]
A:admin@R16-IXR# info flat
    epipe "R5-R16" admin-state enable
    epipe "R5-R16" service-id 4000
    epipe "R5-R16" customer "1"
    epipe "R5-R16" service-mtu 1514
    epipe "R5-R16" { sap 1/1/c2/1:10 }
    epipe "R5-R16" bgp-evpn evi 4000
    epipe "R5-R16" bgp-evpn local-attachment-circuit "local-ac" eth-tag 165
    epipe "R5-R16" bgp-evpn remote-attachment-circuit "remote-ac" eth-tag 516
    epipe "R5-R16" bgp-evpn mpls 1 admin-state enable
    epipe "R5-R16" bgp-evpn mpls 1 auto-bind-tunnel resolution any
    epipe "R5-R16" bgp-evpn mpls 1 route-next-hop ip-address 16.16.16.16


```

> A path in flex algo 128 must exist to be able to resolve the next-hop for EVPN and BGP-LU routes. In this example, we set the delay statically. E.g.: `configure router interface "toR13" if-attribute delay static 1000`

## Option 2: Color community alternative

> Alternatively, one could use BGP color community which would not require a separate loopback per flex algo. Instead, only a separate node SID per algo is required for the system interface. 
It would also avoid the need of the route-next-hop per service setting. However, it would require export policies for the EVPN service on egress PE and import policy on ingress PE to match the color community and map it to the specific flex algo.

Both target and color extended communities must be added at export on egress PE. Also, there has to be an import policy for the service to steer the traffic with color 100 to flex algo 128.

### 1. PE

R16
```
/configure policy-options      
    community "color-100" { member "color:00:100" }
    community "vsi-4010" { member "target:65000:4010" }
    policy-statement "epipe-R5R16-export-c100" default-action action-type accept
    policy-statement "epipe-R5R16-export-c100" default-action community add ["color-100" "vsi-4010"]
    policy-statement "epipe-R5R16-import-c100" entry 10 from community expression "[vsi-4010] AND [color-100]"
    policy-statement "epipe-R5R16-import-c100" entry 10 action action-type accept
    policy-statement "epipe-R5R16-import-c100" entry 10 action flex-algo 128
```

```
/configure service epipe "R5-R16-flexalgo"
    admin-state enable
    service-id 4010
    customer "1"
    service-mtu 1514
    bgp 1 vsi-import ["epipe-R5R16-import-c100"]
    bgp 1 vsi-export ["epipe-R5R16-export-c100"]
    sap 1/1/c2/1:128 { }
    bgp-evpn evi 4010
    bgp-evpn local-attachment-circuit "local-ac" eth-tag 165128
    bgp-evpn remote-attachment-circuit "remote-ac" eth-tag 516128
    bgp-evpn mpls 1 admin-state enable
    bgp-evpn mpls 1 auto-bind-tunnel resolution any
```

R5
```
/configure policy-options 
    community "color-100" { member "color:00:100" }
    community "vsi-4010" { member "target:65000:4010" }
    policy-statement "epipe-R5R16-export-c100" default-action action-type accept
    policy-statement "epipe-R5R16-export-c100" default-action community add ["color-100" "vsi-4010"]
    policy-statement "epipe-R5R16-import-c100" entry 10 from community expression "[vsi-4010] AND [color-100]"
    policy-statement "epipe-R5R16-import-c100" entry 10 action action-type accept
    policy-statement "epipe-R5R16-import-c100" entry 10 action flex-algo 128
```

```
/configure service epipe "R5-R16-flexalgo"
    admin-state enable
    service-id 4010
    customer "1"
    service-mtu 1514
    bgp 1 vsi-import ["epipe-R5R16-import-c100"]
    bgp 1 vsi-export ["epipe-R5R16-export-c100"]
    sap 1/1/c4/1:128 { }
    bgp-evpn evi 4010
    bgp-evpn local-attachment-circuit "local-ac" eth-tag 516128
    bgp-evpn remote-attachment-circuit "remote-ac" eth-tag 165128
    bgp-evpn mpls 1 admin-state enable
    bgp-evpn mpls 1 auto-bind-tunnel resolution any
```

### 2. ABR (RR inline)

In order to have a path available in Flex Algo 128 to the BGP-LU NH (10.0.0.5 and 10.0.20.16 in this example), these routes will be redistributed between ISIS instances for lab purposes.

R11
```
/configure policy-options  
    prefix-list "R05" { prefix 10.0.0.5/32 type exact }
    prefix-list "R16" { prefix 10.0.20.16/32 type exact }
    policy-statement "isis0-to-isis1-flexalgo" entry 10 from prefix-list ["R05"]
    policy-statement "isis0-to-isis1-flexalgo" entry 10 from protocol name [isis]
    policy-statement "isis0-to-isis1-flexalgo" entry 10 from protocol instance 0
    policy-statement "isis0-to-isis1-flexalgo" entry 10 to protocol name [isis]
    policy-statement "isis0-to-isis1-flexalgo" entry 10 to protocol instance 1
    policy-statement "isis0-to-isis1-flexalgo" entry 10 action action-type accept
    policy-statement "isis1-to-isis0-flexalgo" entry 10 from prefix-list ["R16"]
    policy-statement "isis1-to-isis0-flexalgo" entry 10 from protocol name [isis]
    policy-statement "isis1-to-isis0-flexalgo" entry 10 from protocol instance 1
    policy-statement "isis1-to-isis0-flexalgo" entry 10 to protocol name [isis]
    policy-statement "isis1-to-isis0-flexalgo" entry 10 to protocol instance 0
    policy-statement "isis1-to-isis0-flexalgo" entry 10 action action-type accept
```

```
/configure router isis 0
    export-policy ["isis1-to-isis0-flexalgo"]
```

```
/configure router isis 1
    export-policy ["isis0-to-isis1-flexalgo"]
```

Addionally, the Anycast loopbacks used must have a Node SID for Flex Algo 128
```
/configure router "Base" isis 1 interface "BGPAnycast-Access" flex-algo 128 ipv4-node-sid index 222
/configure router "Base" isis 0 interface "BGPAnycast-Core" flex-algo 128 ipv4-node-sid index 111
```

### 3. Useful commands
```
/show router isis
/show router isis flex-algo 128
/show router isis prefix-sids algo 128
/show router isis database R05-SR.00-00 detail 
/show router isis 1 routes ipv4-unicast 10.0.0.5/32 flex-algo 128 detail
/show router isis routes ipv4-unicast 10.0.20.16/32 flex-algo 128 detail
 /show router isis routes ipv4-unicast 10.0.20.16/32 flex-algo 128
/show service id "R5-R16-flexalgo" base
```

### 4. Troubleshooting

To compare the paths between flex algo 0 and 128, one can use the `oam lsp-trace` command.

Flex Algo 0
```
A:admin@R05-SR# /oam lsp-trace sr-isis prefix 10.0.20.16/32           
lsp-trace to 10.0.20.16/32: 1 hops min, 30 hops max, 104 byte packets
1  10.0.0.7  rtt=1.62ms rc=8(DSRtrMatchLabel) rsc=1  
2  10.0.0.9  rtt=2.73ms rc=8(DSRtrMatchLabel) rsc=1  
3  10.0.0.11  rtt=2.82ms rc=8(DSRtrMatchLabel) rsc=1  
4  10.0.20.13  rtt=4.45ms rc=8(DSRtrMatchLabel) rsc=1  
5  10.0.20.15  rtt=6.63ms rc=8(DSRtrMatchLabel) rsc=1  
6  10.0.20.16  rtt=7.16ms rc=3(EgressRtr) rsc=1 
```

Flex Algo 128
```
A:admin@R05-SR# /oam lsp-trace sr-isis prefix 10.0.20.16/32 flex-algo 128
lsp-trace to 10.0.20.16/32: 1 hops min, 30 hops max, 104 byte packets
1  10.0.0.6  rtt=1.83ms rc=8(DSRtrMatchLabel) rsc=1 
2  10.0.0.8  rtt=4.05ms rc=8(DSRtrMatchLabel) rsc=1  
3  10.0.0.10  rtt=3.19ms rc=8(DSRtrMatchLabel) rsc=1  
4  10.0.0.9  rtt=4.16ms rc=8(DSRtrMatchLabel) rsc=1  
5  10.0.0.11  rtt=3.13ms rc=8(DSRtrMatchLabel) rsc=1  
6  10.0.20.13  rtt=4.99ms rc=8(DSRtrMatchLabel) rsc=1  
7  10.0.20.15  rtt=6.65ms rc=8(DSRtrMatchLabel) rsc=1  
8  10.0.20.16  rtt=6.48ms rc=3(EgressRtr) rsc=1 
```