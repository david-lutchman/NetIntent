# RouterOS 7.12.1
# model = RB5009UG+S+IN
# serial number = BR0001RB5009

/system identity
set name=MIKROTIK-BRANCH-GW01

/system clock
set time-zone-name=UTC

/interface ethernet
add name=ether1 comment="WAN-ISP-UPLINK" disabled=no mtu=1500
add name=ether2 comment="BRANCH-LAN-TRUST" disabled=no mtu=1500
add name=ether3 comment="BRANCH-VOICE-LAN" disabled=no mtu=1500
add name=ether4 comment="BRANCH-GUEST-WIFI" disabled=no mtu=1500
add name=ether5 comment="OOB-MGMT" disabled=no mtu=1500
add name=ether6 comment="SPARE-UNUSED" disabled=yes
add name=ether7 comment="SPARE-UNUSED" disabled=yes
add name=ether8 comment="SPARE-UNUSED" disabled=yes

/interface vlan
add name=vlan10 vlan-id=10 interface=ether2 comment="User-LAN"
add name=vlan20 vlan-id=20 interface=ether2 comment="Voice"
add name=vlan30 vlan-id=30 interface=ether2 comment="Servers"
add name=vlan40 vlan-id=40 interface=ether4 comment="Guest-WiFi"

/ip address
add address=203.0.113.10/30 interface=ether1 comment="WAN-ISP"
add address=192.168.70.1/24 interface=vlan10 comment="Branch-LAN-Trust"
add address=192.168.71.1/24 interface=vlan20 comment="Branch-Voice-LAN"
add address=192.168.72.1/24 interface=vlan30 comment="Branch-Servers"
add address=192.168.73.1/24 interface=vlan40 comment="Branch-Guest-WiFi"
add address=192.168.200.6/24 interface=ether5 comment="OOB-MGMT"

/ip route
add dst-address=0.0.0.0/0 gateway=203.0.113.9 comment="Default-Route"
add dst-address=10.30.0.0/24 gateway=192.168.70.254 comment="HQ-Trust"
add dst-address=10.50.0.0/24 gateway=192.168.70.254 comment="HQ-Servers"
add dst-address=10.99.0.0/24 gateway=192.168.70.254 comment="HQ-MGMT"

/ip firewall filter
add chain=input action=accept protocol=tcp dst-port=22 src-address=10.99.0.0/24 comment="Allow SSH from MGMT"
add chain=input action=accept src-address=10.0.0.50/32 protocol=udp dst-port=161 comment="Allow SNMP from NMS"
add chain=input action=accept protocol=icmp comment="Allow ICMP"
add chain=input action=drop comment="Drop all other input"
add chain=forward action=accept src-address=192.168.70.0/24 dst-address=!192.168.73.0/24 protocol=tcp dst-port=80 comment="Branch LAN HTTP"
add chain=forward action=accept src-address=192.168.70.0/24 dst-address=!192.168.73.0/24 protocol=tcp dst-port=443 comment="Branch LAN HTTPS"
add chain=forward action=accept src-address=192.168.71.0/24 protocol=udp dst-port=5060 comment="Voice SIP"
add chain=forward action=accept src-address=192.168.71.0/24 protocol=udp dst-port=16384-32767 comment="Voice RTP"
add chain=forward action=accept src-address=192.168.73.0/24 protocol=tcp dst-port=80,443 comment="Guest web only"
add chain=forward action=drop src-address=192.168.73.0/24 dst-address=192.168.70.0/24 comment="Guest deny LAN"
add chain=forward action=drop src-address=192.168.73.0/24 dst-address=192.168.71.0/24 comment="Guest deny Voice"
add chain=forward action=drop comment="Implicit deny"

/ip firewall nat
add chain=srcnat action=masquerade out-interface=ether1 src-address=192.168.70.0/24 comment="Branch LAN NAT"
add chain=srcnat action=masquerade out-interface=ether1 src-address=192.168.73.0/24 comment="Guest NAT"

/ip ipsec profile
add name=IKEv2-PROFILE hash-algorithm=sha256 enc-algorithm=aes-256 dh-group=modp2048

/ip ipsec peer
add name=HQ-PEER address=172.16.10.1 profile=IKEv2-PROFILE exchange-mode=ike2

/ip ipsec identity
add peer=HQ-PEER auth-method=pre-shared-key secret="$1$branchikepsk987654"

/ip ipsec policy
add src-address=192.168.70.0/24 dst-address=10.30.0.0/24 peer=HQ-PEER tunnel=yes action=encrypt

/ip dns
set servers=10.0.0.10,8.8.8.8 allow-remote-requests=yes

/snmp
set enabled=yes contact="netops@lab.internal" location="Branch-Office-3-IDF"

/system ntp client
set enabled=yes

/system ntp client servers
add address=10.0.0.10

/user
add name=admin password="$1$branchadminpass" group=full
add name=auditor password="$1$branchauditpass" group=read
