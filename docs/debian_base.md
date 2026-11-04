# Stage 01 — Base Debian / Architecture

## Existing Environment

The original server was built using:

* **Operating system:** Debian GNU/Linux 13 (Trixie)
* **Observed Debian version:** 13.7
* **Package architecture:** `amd64`
* **Virtualization provider:** Oracle VirtualBox
* **Current hostname:** `zon`

## Reproduction Requirements

The new VM must:

1. Use a Debian 13 compatible base box.
2. Use an x86-64 (`amd64`) architecture.
3. Use a provider compatible with the host CPU architecture.
4. Reproduce the required server configuration through provisioning.

## Base Image Responsibilities

The base box provides the initial operating system, kernel, and basic filesystem.

We do not need to reproduce machine-specific identifiers such as the machine ID, boot ID, or product UUID.

The exact kernel version is not a requirement unless a later project requirement explicitly depends on it.

## Current Decision

The existing machine uses VirtualBox and `amd64`. We will use this information when selecting the Vagrant provider and base box in Stage 19.

**Status: Information collected. Base-box selection pending Stage 19.**
