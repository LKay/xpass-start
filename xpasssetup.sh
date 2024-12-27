#!/bin/bash
model=`ubnt-device-info model`
tun_interface=ip6tnl1
ext_interface=eth4
IPv6=""
heartbeat_addr=8.8.8.8
if [[ $model == "UniFi Dream Machine SE" ]]
then
    ext_interface=eth8
elif [[ $model == "UniFi Dream Machine Pro" ]]
then
    ext_interface=eth8
elif [[ $model == "UniFi Dream Machine" ]]
then
    ext_interface=eth4
fi
echo "Detected $model. Setting external interface to $ext_interface"

create_tunnel () {
    # Delete the existing Tunnel because it is in the way.
    IPv6=`ip address show $ext_interface  |grep  inet6 |head -1 | awk '{print $2}'| awk -F/ '{print $1}'`
    ip link delete $tun_interface 

    # Connect to dgw.xpass.jp
    ip -6 tunnel add $tun_interface mode ipip6 remote 2001:f60:0:200::1:1 local $IPv6 encaplimit none dev $ext_interface 

    # Set this side's IPv4 address to 192.0.0.2/29 according to the DS-Lite specifications
    ip addr add 192.0.0.2/29 dev $tun_interface 

    # Enable the device
    ip link set dev $tun_interface up

    # Set the default route via Tunnel
    ip route add default dev $tun_interface 
}

check_connection () {
    ip address list |grep $tun_interface $1>/dev/null
    if [[ $? -eq 1 ]]; then
        echo "Tunnel interface not found. Trying to recreate tunnel"
        create_tunnel
    fi 
    ip address show $tun_interface |grep $ext_interface $1>/dev/null
    if [[ $? -eq 1 ]]; then
        echo "Tunnel interface not bound to interface. Trying to recreate tunnel"
        create_tunnel
    fi 
    ping -c 5 $heartbeat_addr | grep "64 bytes from" $1>/dev/null
    if [[ $? -eq 1 ]]; then
        echo "Ping to $heartbeat_addr failed. Try to recreate tunnel"
        create_tunnel
    fi
}

while true
do
    check_connection
    sleep 10 
done
