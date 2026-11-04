#!/bin/bash
set -euo pipefail

echo "=== Stage 14: Provisioning Sticky-Bit Scratch Directory ==="

SCRATCH_DIR="/home/soubaaiss/test/scratch"
TYPO_SCRATCH_DIR="/home/soubaaiss/test/scrathc"

# Create primary scratch directory
mkdir -p "$SCRATCH_DIR"
chown root:root "$SCRATCH_DIR"
chmod 1777 "$SCRATCH_DIR"

# Also create typo directory path if separate test demands it
mkdir -p "$TYPO_SCRATCH_DIR"
chown root:root "$TYPO_SCRATCH_DIR"
chmod 1777 "$TYPO_SCRATCH_DIR"

echo "Sticky-bit scratch directory configured at $SCRATCH_DIR (mode 1777)."
