# RouterOS 7.12.1
# by RouterOS 7.12.1
#
# model = CCR2004-1G-12S+2XS
# serial number = HQ0001CCRGW

/system identity
set name=MIKROTIK-CORE-GW01

/system clock
set time-zone-name=UTC

/ip address
add address=10.1.0.9/30 interface=ether1 comment="UPLINK-TO-JUNIPER-DIST-SW01"
add address=10.1.0.13/30 interface=ether2 comment="UPLINK-TO-ARISTA-CORE-SW01"
add address=203.0.113.1/30 interface=ether3 comment="WAN-ISP-UPLINK"
add address=10.0.0.1/24 interface=ether4 comment="CORE-SERVERS-LAN"
add address=10.99.0.254/24 interface=ether5 comment="OOB-MGMT"

/interface ethernet
add name=ether1 comment="UPLINK-TO-JUNIPER-DIST-SW01" disabled=no mtu=9000
add name=ether2 comment="UPLINK-TO-ARISTA-CORE-SW01" disabled=no mtu=9000
add name=ether3 comment="WAN-ISP-UPLINK" disabled=no mtu=1500
add name=ether4 comment="CORE-SERVERS-LAN" disabled=no mtu=9000
add name=ether5 comment="OOB-MGMT" disabled=no mtu=1500
add name=ether6 comment="SPARE-UNUSED" disabled=yes
add name=ether7 comment="SPARE-UNUSED" disabled=yes

/interface bridge
add name=bridge-lo comment="Loopback-Bridge"

/ip address
add address=10.255.1.1/32 interface=bridge-lo comment="Loopback"

/ip route
add dst-address=0.0.0.0/0 gateway=203.0.113.2 comment="DEFAULT-ROUTE"
add dst-address=10.0.0.0/8 gateway=10.1.0.10 comment="INTERNAL-SUMMARY"
add dst-address=172.16.0.0/12 gateway=10.1.0.10 comment="VPN-SUMMARY"

/routing ospf instance
add name=ospf-main router-id=10.255.1.1

/routing ospf area
add name=backbone area-id=0.0.0.0 instance=ospf-main

/routing ospf interface-template
add interfaces=ether1 area=backbone type=ptp hello-interval=5s dead-interval=20s auth=md5 auth-key="ospfkey123"
add interfaces=ether2 area=backbone type=ptp hello-interval=5s dead-interval=20s auth=md5 auth-key="ospfkey123"
add interfaces=bridge-lo area=backbone passive

/routing bgp connection
add name=ISP-BGP remote.address=203.0.113.2 remote.as=65100 local.address=203.0.113.1 local.role=ebgp
add name=IBGP-DIST remote.address=10.1.0.10 remote.as=65001 local.address=10.1.0.9 local.role=ibgp

/ip firewall filter
add chain=input action=accept protocol=ospf comment="Allow OSPF"
add chain=input action=accept src-address=10.99.0.0/24 protocol=tcp dst-port=22 comment="Allow SSH from MGMT"
add chain=input action=accept src-address=10.0.0.50/32 protocol=udp dst-port=161 comment="Allow SNMP"
add chain=input action=accept protocol=icmp comment="Allow ICMP"
add chain=input action=drop comment="Drop all other input"
add chain=forward action=accept connection-state=established,related comment="Allow established"
add chain=forward action=drop connection-state=invalid comment="Drop invalid"

/ip firewall nat
add chain=srcnat action=masquerade out-interface=ether3 comment="Internet NAT"

/snmp
set enabled=yes contact="netops@lab.internal" location="DC1-Core-Rack" trap-community="$1$snmptrap"

/snmp community
add name="$1$snmpcomm123" addresses=10.0.0.50/32 read-access=yes

/system ntp client
set enabled=yes

/system ntp client servers
add address=10.0.0.10
add address=10.0.0.11

/system logging
add topics=info action=remote
add topics=warning action=remote

/system logging action
add name=remote remote=10.0.0.50 src-address=10.99.0.254

/radius
add server=10.0.0.20 secret="$1$radiussecret" service=login

/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set ssh port=22 disabled=no
set api disabled=yes
set winbox disabled=yes
set www-ssl disabled=yes

/user
add name=admin password="$1$adminhashedpassword" group=full comment="Admin user"
add name=netops password="$1$netopshashedpassword" group=read comment="Read-only ops"
