#!/bin/bash
export bash_start_tor_at_boot_is_loaded=true

# This module is a dependency for (and has these dependencies):
START_TOR_AT_BOOT_PARENT_DEPS=("bash-start-tor-at-boot" "bash-ssh-over-tor")
# This module has dependencies:
START_TOR_AT_BOOT_REQUIRED_DEPS=("bash-log" "bash-package-installer")

START_TOR_AT_BOOT_SRC_PATH=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
START_TOR_AT_BOOT_PATH=$(readlink -f "$START_TOR_AT_BOOT_SRC_PATH/../")

# Loads the bash log dependency, and the dependency loader.
function load_dependency_manager() {
  if [ -d "$START_TOR_AT_BOOT_PATH/dependencies/bash-log" ]; then
    # shellcheck disable=SC1091
    source "$START_TOR_AT_BOOT_PATH/dependencies/bash-log/src/dependency_manager.sh"
  elif [ -d "$START_TOR_AT_BOOT_PATH/../bash-log" ]; then
    # shellcheck disable=SC1091
    source "$START_TOR_AT_BOOT_PATH/../bash-log/src/dependency_manager.sh"
  else
    echo "ERROR: bash-log dependency is not found."
    exit 1
  fi
}
load_dependency_manager

# Load required dependencies.
for required_dependency in "${START_TOR_AT_BOOT_REQUIRED_DEPS[@]}"; do
  load_required_dependency "$START_TOR_AT_BOOT_PATH" "$required_dependency"
done

# Load dependencies that can be a parent dependency (=this module is a
# dependency of that module/dependency).
for parent_dep in "${START_TOR_AT_BOOT_PARENT_DEPS[@]}"; do
  load_parent_dependency "$START_TOR_AT_BOOT_PATH" "$parent_dep"
done

LOG_LEVEL_ALL # set log level to all, otherwise, NOTICE, INFO, DEBUG, TRACE will not be logged.
B_LOG --file log/multiple-outputs.txt --file-prefix-enable --file-suffix-enable

# Load prerequisites installation.
NOTICE "Loading from:$START_TOR_AT_BOOT_SRC_PATH"
function load_functions() {

  # shellcheck disable=SC1091
  source "$START_TOR_AT_BOOT_SRC_PATH/GLOBAL_VARS.sh"

  # shellcheck disable=SC1091
  source "$START_TOR_AT_BOOT_SRC_PATH/configuration/activate_systemct_services.sh"
  # shellcheck disable=SC1091
  source "$START_TOR_AT_BOOT_SRC_PATH/configuration/uwf_status.sh"
  # shellcheck disable=SC1091
  source "$START_TOR_AT_BOOT_SRC_PATH/installation.sh"
  # shellcheck disable=SC1091
  source "$START_TOR_AT_BOOT_SRC_PATH/configuration.sh"

  # Load tor helper functions.
  # shellcheck disable=SC1091
  source "$START_TOR_AT_BOOT_SRC_PATH/tor_status/create_tor_connection.sh"
  # shellcheck disable=SC1091
  source "$START_TOR_AT_BOOT_SRC_PATH/tor_status/tor_status.sh"
  # shellcheck disable=SC1091
  source "$START_TOR_AT_BOOT_SRC_PATH/tor_status/verify_https_onion_is_available.sh"

  # Load onion domain helper functions.
  # shellcheck disable=SC1091
  source "$START_TOR_AT_BOOT_SRC_PATH/onion_domain/stop_tor_if_it_is_running.sh"
  # shellcheck disable=SC1091
  source "$START_TOR_AT_BOOT_SRC_PATH/onion_domain/onion_domain_exists.sh"

  # Load parsing helper functions.
  # shellcheck disable=SC1091
  source "$START_TOR_AT_BOOT_SRC_PATH/parsing/file_editing.sh"

  # Load file_editing helper functions.
  # shellcheck disable=SC1091
  source "$START_TOR_AT_BOOT_SRC_PATH/verification/assert_not_exists.sh"
  # shellcheck disable=SC1091
  source "$START_TOR_AT_BOOT_SRC_PATH/verification/assert_not_exists.sh"
  # shellcheck disable=SC1091
  source "$START_TOR_AT_BOOT_SRC_PATH/verification/assert_exists.sh"

  # shellcheck disable=SC1091
  source "$START_TOR_AT_BOOT_SRC_PATH/configuration.sh"

}
load_functions
