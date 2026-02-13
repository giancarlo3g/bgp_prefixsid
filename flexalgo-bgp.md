

## Egress PE

Create an additional loopback for flex algo and advertise with via ISIS and BGP-LU changing its next-hop.

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
    isis 1 interface "flexalgo128" passive true
    isis 1 interface "flexalgo128" ipv4-node-sid index 216
    isis 1 interface "flexalgo128" ipv4-node-sid clear-n-flag true
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

```
(gl)[/configure policy-options]
A:admin@R16-IXR# info flat 
    community "access-1" { member "65000:1" }
    community "access-2" { member "65000:2" }
    community "core" { member "65000:0" }
    community "flexalgo128" { member "color:10:100" }
    prefix-list "flexalgo128" { prefix 16.16.16.16/32 type exact }
    prefix-list "if-system" { prefix 10.0.20.16/32 type exact }
    policy-statement "export-label-system" entry 10 from prefix-list ["if-system"]
    policy-statement "export-label-system" entry 10 from protocol name [direct]
    policy-statement "export-label-system" entry 10 action action-type accept
    policy-statement "export-label-system" entry 10 action community add ["access-2"]
    policy-statement "export-label-system" entry 20 from prefix-list ["flexalgo128"]
    policy-statement "export-label-system" entry 20 from protocol name [direct]
    policy-statement "export-label-system" entry 20 action action-type accept
    policy-statement "export-label-system" entry 20 action next-hop 16.16.16.16
```

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

## Inline RR (ABR)

An additional Anycast loopback interface (11.11.11.11) for flex algo 128 that is used as next-hop for the ingress PE flex algo loopback (16.16.16.16)

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
    interface "toR12" port 1/1/c2/1
    interface "toR13" port 1/1/c3/1
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
    isis 0 interface "flexalgo128-core" passive true
    isis 0 interface "flexalgo128-core" ipv4-node-sid index 211
    isis 0 interface "flexalgo128-core" ipv4-node-sid clear-n-flag true
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
    policy-statement "change-NH-access" entry 10 from family [label-ipv4]
    policy-statement "change-NH-access" entry 10 from protocol name [bgp-label]
    policy-statement "change-NH-access" entry 10 action action-type accept
    policy-statement "change-NH-access" entry 10 action next-hop 4.4.4.4
    policy-statement "change-NH-flexalgo128" { entry 10 }
    policy-statement "export-label-system" entry 10 from prefix-list ["if-system"]
    policy-statement "export-label-system" entry 10 from protocol name [direct]
    policy-statement "export-label-system" entry 10 action action-type accept
    policy-statement "export-label-system" entry 10 action community add ["access-2" "core"]
    policy-statement "routers-system" entry 10 from prefix-list ["routers-system-ip"]
    policy-statement "routers-system" entry 10 action action-type accept
```

## Ingress PE

No changes

```
(gl)[/configure service]
A:admin@R05-SR# info flat
    epipe "R5-R16" admin-state enable
    epipe "R5-R16" service-id 4000
    epipe "R5-R16" customer "1"
    epipe "R5-R16" service-mtu 1514
    epipe "R5-R16" { sap 1/1/c4/1:10 }
    epipe "R5-R16" bgp-evpn evi 4000
    epipe "R5-R16" bgp-evpn local-attachment-circuit "local-ac" eth-tag 516
    epipe "R5-R16" bgp-evpn remote-attachment-circuit "remote-ac" eth-tag 165
    epipe "R5-R16" bgp-evpn mpls 1 admin-state enable
    epipe "R5-R16" bgp-evpn mpls 1 auto-bind-tunnel resolution any

```