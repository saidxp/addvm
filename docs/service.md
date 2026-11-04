# Stage 05 — Systemd Service

## 1. Purpose

The `linux` project contains a custom systemd service that continuously runs a system monitoring script.

The service is responsible for starting the script, keeping it running, restarting it if it exits, and starting it automatically during boot.

Project files:

```text
linux/
├── scripts/
│   └── myservice.sh
└── systemd/
    └── myservice.service
```

---

## 2. Installed Service

The systemd unit is installed at:

```text
/etc/systemd/system/myservice.service
```

Its configuration is:

```ini
[Unit]
Description=My system monitoring service

[Service]
ExecStart=/usr/local/bin/myservice.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### Service configuration

```text
Description
    ↓
My system monitoring service

ExecStart
    ↓
/usr/local/bin/myservice.sh

Restart=always
    ↓
restart the service whenever the process exits

RestartSec=5
    ↓
wait 5 seconds before restarting

WantedBy=multi-user.target
    ↓
service can be enabled for normal system boot
```

---

## 3. Installed Script

The monitoring script is installed at:

```text
/usr/local/bin/myservice.sh
```

Current permissions and ownership:

```text
-rwxrwxr-x 1 root root
```

The script contains:

```sh
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
    ip -4 addr show enp0s3

    echo "Gateway:"
    ip route | grep default

    echo "========================"

    sleep 30
done
```

The script therefore reports:

```text
Date and time
Boot mode
Uptime
Root filesystem usage
Memory usage
IPv4 address of enp0s3
Default gateway
```

It repeats the check every:

```text
30 seconds
```

---

## 4. Service State

The service is currently:

```text
active (running)
```

The current service status confirms:

```text
Loaded: loaded (...; enabled; preset: enabled)
Active: active (running)
```

The service is also explicitly confirmed as enabled:

```text
systemctl is-enabled myservice.service
```

Result:

```text
enabled
```

Therefore:

```text
enabled
    ↓
starts automatically during boot

active (running)
    ↓
currently running
```

These are separate properties.

---

## 5. Process

The service currently runs:

```text
/usr/local/bin/myservice.sh
```

through:

```text
/bin/sh
```

The service's main process is managed by systemd.

The script also starts:

```text
sleep 30
```

between monitoring cycles.

---

## 6. Journal

The service writes its standard output to the systemd journal.

It can be inspected with:

```bash
journalctl -u myservice.service
```

The current journal confirms that the script reports network information and the default gateway.

For example:

```text
Network:
...
inet 192.168.11.245/24 ...
Gateway:
default via 192.168.11.1 dev enp0s3 ...
```

The journal is therefore part of the normal systemd service behavior and does not require a separate logging application.

---

## 7. Installation Requirements

To reproduce this service, provisioning must eventually:

```text
1. Install the script
        ↓
/usr/local/bin/myservice.sh

2. Make the script executable
        ↓
chmod +x

3. Install the systemd unit
        ↓
/etc/systemd/system/myservice.service

4. Reload systemd
        ↓
systemctl daemon-reload

5. Enable the service
        ↓
systemctl enable myservice.service

6. Start the service
        ↓
systemctl start myservice.service
```

The exact provisioning implementation will be created later in the project.

---

## 8. Dynamic Information

The monitoring script reads information from the machine at runtime.

For example:

```text
IP address
gateway
uptime
disk usage
memory usage
boot mode
```

These values should **not** be hard-coded into the service configuration.

The script discovers them when it runs.

For example:

```text
ip -4 addr show enp0s3
        ↓
current address

ip route | grep default
        ↓
current gateway
```

This is important because the rebuilt VM may receive a different DHCP address.

---

## 9. Stage 05 Conclusion

The original Linux project uses:

```text
/etc/systemd/system/myservice.service
        ↓
/usr/local/bin/myservice.sh
        ↓
system monitoring every 30 seconds
```

The service configuration requires:

```text
Restart=always
RestartSec=5
WantedBy=multi-user.target
```

The service must be:

```text
enabled
active (running)
```

after provisioning.

Its output is available through:

```bash
journalctl -u myservice.service
```

**Stage 05 — Systemd Service: COMPLETE**
