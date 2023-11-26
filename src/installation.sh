#!/bin/bash

function install_ssh_requirements() {
  ensure_apt_pkg "openssh-server" 0

  ensure_service_is_started "ssh"
  ensure_service_starts_at_boot "ssh"
  ensure_uwf_is_enabled
}
