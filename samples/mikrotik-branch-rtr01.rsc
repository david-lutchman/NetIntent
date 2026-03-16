# 2026-03-16 10:22:15 by RouterOS 7.14.2
# software id = ABC1-DEFG
# model = RB5009UPr+S+
# serial number = HE1234567890
/system identity
set name=MT-BRANCH-RTR01
/system clock
set time-zone-name=America/New_York
/ip dns
set servers=10.100.99.10,10.100.99.11 allow-remote-requests=yes cache-size=4096KiB
/interface bridge
add name=bridge-lan vlan-filtering=yes pvid=20 protocol-mode=none
/interface bridge port
add bridge=bridge-lan interface=ether3 pvid=20
add bridge=bridge-lan interface=ether4 pvid=20
add bridge=bridge-lan interface=ether5 pvid=30
add bridge=bridge-lan interface=ether6 pvid=40
add bridge=bridge-lan interface=ether7 pvid=20
add bridge=bridge-lan interface=ether8 pvid=20
/interface bridge vlan
add bridge=bridge-lan tagged=bridge-lan vlan-ids=20
add bridge=bridge-lan tagged=bridge-lan vlan-ids=30
add bridge=bridge-lan tagged=bridge-lan vlan-ids=40
add bridge=bridge-lan tagged=bridge-lan vlan-ids=99
/interface vlan
add interface=bridge-lan name=vlan20-workstations vlan-id=20
add interface=bridge-lan name=vlan30-voip vlan-id=30
add interface=bridge-lan name=vlan40-wireless vlan-id=40
add interface=bridge-lan name=vlan99-mgmt vlan-id=99
/interface ethernet
set [ find default-name=ether1 ] comment=WAN-ISP2-PPPoE
set [ find default-name=ether2 ] comment=to-NOKIA-PE-RTR01-1/1/2
set [ find default-name=ether3 ] comment=LAN-DESK01
set [ find default-name=ether4 ] comment=LAN-DESK02
set [ find default-name=ether5 ] comment=VOIP-PHONE01
set [ find default-name=ether6 ] comment=WAP-BRANCH-AP01
set [ find default-name=ether7 ] comment=LAN-DESK03
set [ find default-name=ether8 ] comment=LAN-DESK04
set [ find default-name=sfp-sfpplus1 ] comment=UNUSED disabled=yes
/interface pppoe-client
add interface=ether1 name=pppoe-isp2 user=acme-branch01@isp2.net password=pPp0eP@ss2026! \
    add-default-route=yes default-route-distance=1 use-peer-dns=no disabled=no
/ip address
add address=172.16.0.34/30 interface=ether2 comment=to-NOKIA-PE-RTR01-1/1/2 network=172.16.0.32
add address=10.100.20.1/24 interface=vlan20-workstations comment=WORKSTATIONS-GW network=10.100.20.0
add address=10.100.30.1/24 interface=vlan30-voip comment=VOIP-GW network=10.100.30.0
add address=10.100.40.1/24 interface=vlan40-wireless comment=WIRELESS-GW network=10.100.40.0
add address=10.100.99.9/24 interface=vlan99-mgmt comment=MGMT network=10.100.99.0
/ip dhcp-server network
add address=10.100.20.0/24 gateway=10.100.20.1 dns-server=10.100.99.10,10.100.99.11 \
    domain=branch01.acme-corp.internal
add address=10.100.30.0/24 gateway=10.100.30.1 dns-server=10.100.99.10,10.100.99.11
add address=10.100.40.0/24 gateway=10.100.40.1 dns-server=10.100.99.10,10.100.99.11
/ip pool
add name=pool-workstations ranges=10.100.20.100-10.100.20.250
add name=pool-voip ranges=10.100.30.100-10.100.30.200
add name=pool-wireless ranges=10.100.40.100-10.100.40.250
/ip dhcp-server
add address-pool=pool-workstations interface=vlan20-workstations name=dhcp-workstations \
    lease-time=8h disabled=no
add address-pool=pool-voip interface=vlan30-voip name=dhcp-voip \
    lease-time=12h disabled=no
add address-pool=pool-wireless interface=vlan40-wireless name=dhcp-wireless \
    lease-time=4h disabled=no
/ip route
add dst-address=10.0.0.0/8 gateway=172.16.0.33 comment=CORP-NETWORKS-VIA-NOKIA distance=10
add dst-address=172.16.0.0/12 gateway=172.16.0.33 comment=INFRASTRUCTURE-VIA-NOKIA distance=10
/ip firewall filter
add chain=input action=accept connection-state=established,related comment="Accept established"
add chain=input action=accept protocol=icmp comment="Accept ICMP"
add chain=input action=accept src-address=10.100.99.0/24 protocol=tcp dst-port=22,8291 \
    comment="Accept SSH/Winbox from MGMT"
add chain=input action=accept protocol=udp dst-port=500,4500 comment="Accept IKEv2"
add chain=input action=accept protocol=ospf comment="Accept OSPF"
add chain=input action=drop in-interface=pppoe-isp2 comment="Drop WAN input"
add chain=input action=drop comment="Drop all other input"
add chain=forward action=accept connection-state=established,related comment="Accept established forward"
add chain=forward action=accept src-address=10.100.0.0/16 comment="Accept LAN to any"
add chain=forward action=drop comment="Drop all other forward"
/ip firewall nat
add chain=srcnat out-interface=pppoe-isp2 action=masquerade comment="NAT to ISP2"
/ip firewall address-list
add list=bogons address=0.0.0.0/8
add list=bogons address=10.0.0.0/8
add list=bogons address=100.64.0.0/10
add list=bogons address=127.0.0.0/8
add list=bogons address=169.254.0.0/16
add list=bogons address=172.16.0.0/12
add list=bogons address=192.168.0.0/16
/ip firewall raw
add chain=prerouting in-interface=pppoe-isp2 src-address-list=bogons action=drop \
    comment="Drop bogons from WAN"
/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set api disabled=yes
set api-ssl disabled=yes
set winbox address=10.100.99.0/24
set ssh address=10.100.99.0/24
/ip neighbor discovery-settings
set discover-interface-list=none
/system ntp client
set enabled=yes
/system ntp client servers
add address=10.100.99.10
add address=10.100.99.11
/system logging
add topics=critical action=remote
add topics=error action=remote
add topics=firewall action=remote
/system logging action
set remote remote=10.100.99.50 bsd-syslog=yes
/snmp
set enabled=yes contact=noc@acme-corp.internal location="ACME-Branch01-Closet" \
    trap-community=rO-mt-branch01!
/snmp community
set [ find default=yes ] disabled=yes
add name=rO-mt-branch01! read-access=yes write-access=no addresses=10.100.99.0/24
/user
set [ find name=admin ] password=Adm1n!Mt-Br@nch01
add name=netops password=N3t0ps!Mt-Br@nch01 group=full
add name=readonly password=R34d0nly!Mt group=read
/system note
set show-at-login=yes note="ACME Corp - MT-BRANCH-RTR01 - Branch Office 01\n\
    Unauthorized access is prohibited."
