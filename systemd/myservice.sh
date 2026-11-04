#!/bin/sh

while true; do
    echo "===== System Check ====="

    echo "Date:"
    date

    echo "Boot mode:"
    if [ -d /sys/firmware/efi ]; then
        echo "UEFI"
    else
        echo "BIOS/Legacy"
    fi

    echo "Uptime:"
    uptime

    echo "Disk usage:"
    df -h /

    echo "Memory usage:"
    free -h

    echo "Network:"
    ip -4 addr show enp0s3 2>/dev/null || ip -4 addr show

    echo "Gateway:"
    ip route | grep default || true

    echo "========================"

    sleep 30
done
