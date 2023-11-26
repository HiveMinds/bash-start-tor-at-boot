#!/bin/bash

# Load the installer dependency.
source dependencies/bash-package-installer/src/main.sh
source dependencies/bash-log/src/main.sh
LOG_LEVEL_ALL # set log level to all, otherwise, NOTICE, INFO, DEBUG, TRACE will not be logged.

# Load prerequisites installation.
function load_functions() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # shellcheck disable=SC1091
  source "$script_dir/activate_systemct_services.sh"
  # shellcheck disable=SC1091
  source "$script_dir/src/uwf_status.sh"
  # shellcheck disable=SC1091
  source "$script_dir/installation.sh"
}
load_functions

# Execute prerequisites installation.
install_ssh_requirements
