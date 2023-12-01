#!/bin/bash

function ensure_ssh_is_started_at_boot() {
  ensure_service_is_started "ssh"
  ensure_service_starts_at_boot "ssh"

  ensure_uwf_is_enabled

  # THIS IS ESSENTIAL IF YOU GET:
  # [syscall] Unsupported syscall number 39.
  # Source: Comment in: https://askubuntu.com/q/1264335
  # NO SUDO REQUIRED.
  chmod g-w ~/.ssh/config >>/dev/null 2>&1
}

function configure_tor_to_start_at_boot() {
  ensure_ssh_is_started_at_boot

  ensure_service_is_started "tor"

  # Ensure tor is started in the background.
  start_tor_in_background
  # Ensure tor starts at boot.
  ensure_service_starts_at_boot "tor"
}
