#!/bin/bash
set -euo pipefail

echo "=== Stage 04: Installing Required Packages ==="

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y sudo acl openssh-server lvm2

echo "Package installation complete."
