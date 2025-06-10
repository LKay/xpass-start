#!/bin/bash

# === USER CONFIGURATION START ===

FIXED_IPV4=""
AFTR_IPV6="2404:8e00::feed:100"
TUN_IF="xpass0"
WAN_PORT="8"
HEARTBEAT_ADDR="1.1.1.1"

# === USER CONFIGURATION END ===

log() {
  TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
  logger -t "xpass-tunnel" "$TIMESTAMP: $@"
}

UDM_MODEL=$(ubnt-device-info model)
WAN_IF=""

case "$UDM_MODEL" in
  "UniFi Dream Machine")
    WAN_IF=eth4
    ;;
  "UniFi Dream Machine SE" | "UniFi Dream Machine Pro" | "UniFi Dream Machine Pro Max")
    WAN_IF="eth$(($WAN_PORT - 1))"
    ;;
  *)
    log "Error: Unsupported model '$UDM_MODEL'."
    exit 1
    ;;
esac

cleanup () {
    log "Cleaning up tunnel"
    ip tunnel del $TUN_IF 2>/dev/null
    ip link delete $TUN_IF 2>/dev/null
    ip addr flush dev $TUN_IF 2>/dev/null
}

trap "cleanup; exit 0" SIGINT SIGTERM

create_tunnel () {
    LOCAL_IPV6=$(ip address show $WAN_IF | grep inet6 | head -1 | awk '{print $2}' | awk -F/ '{print $1}')
    if [ -z "$LOCAL_IPV6" ]; then
        log "Error: No IPv6 address on $WAN_IF"
        return 1
    fi

    if [ -n "$FIXED_IPV4" ]; then
        TUNNEL_IPV4="$FIXED_IPV4"
    else
        TUNNEL_IPV4=$(curl -s --interface $WAN_IF https://api.ipify.org || echo "")
        if [ -z "$TUNNEL_IPV4" ]; then
            log "Error: Unable to auto-detect dynamic public IPv4. Aborting."
            exit 1
        fi
    fi

    echo "Creating DS-Lite tunnel with local IPv6 $LOCAL_IPV6 and IPv4 $TUNNEL_IPV4 on interface $WAN_IF"

    # Delete the existing Tunnel because it is in the way.
    cleanup

    # Connect to dgw.xpass.jp using the specified AFTR IPv6 address
    ip -6 tunnel add $TUN_IF mode ipip6 remote $AFTR_IPV6 local $LOCAL_IPV6 encaplimit none dev $WAN_IF

    # Set the fixed IPv4 address if enabled. 192.0.0.1/29 is commonly used as the CPE address in DS-Lite setups
    ip addr add $TUNNEL_IPV4 peer 192.0.0.1/29 dev $TUN_IF

    # Set this side's IPv4 address to 192.0.0.2/29 according to the DS-Lite specifications
    ip addr add 192.0.0.2/29 dev $TUN_IF

    # Enable the device
    ip link set dev $TUN_IF up

    # Set the default route via Tunnel
    ip route add default dev $TUN_IF

    log "Tunnel created with local IPv6 $LOCAL_IPV6 and IPv4 $TUNNEL_IPV4 on interface $WAN_IF"
}

check_connection () {
    if ! ip address show $TUN_IF > /dev/null 2>&1; then
        log "Tunnel interface not found"
        create_tunnel
        return
    fi

    if ! ip link show $TUN_IF | grep -q "UP"; then
        log "Tunnel interface down"
        create_tunnel
        return
    fi

    if ! ping -c 3 -W 3 $HEARTBEAT_ADDR | grep -q "64 bytes from"; then
        log "Ping to $HEARTBEAT_ADDR failed"
        create_tunnel
        return
    fi
}

if command -v systemd-notify > /dev/null; then
    SYSTEMD_NOTIFY=1
else
    SYSTEMD_NOTIFY=0
fi

send_ready() {
    if [ $SYSTEMD_NOTIFY -eq 1 ]; then
        systemd-notify --ready
    fi
}

send_watchdog() {
    if [ $SYSTEMD_NOTIFY -eq 1 ]; then
        systemd-notify WATCHDOG=1
    fi
}

# Signal ready after tunnel creation
create_tunnel
send_ready

# Monitor loop
while true; do
    check_connection
    send_watchdog
    sleep 30
done
