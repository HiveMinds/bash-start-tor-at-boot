#!/bin/bash

# This module is a dependency for:
# - bash-create-onion-domains
# - bash-ssh-over-tor
# This module has dependencies:
# - bash-log
# - bash-package-installer

START_TOR_AT_BOOT_SRC_PATH=$(dirname "$(readlink -f "$0")")
START_TOR_AT_BOOT_PATH=$(readlink -f "$START_TOR_AT_BOOT_SRC_PATH/../")

function load_dependencies() {
  local dependency_or_parent_path
  # The path of this repo ends in /bash-create-onion-domains. If it follows:
  # /dependencies/bash-create-onion-domains, then it is a dependency of
  #another module.
  echo "START_TOR_AT_BOOT_PATH=$START_TOR_AT_BOOT_PATH"
  if [[ "$START_TOR_AT_BOOT_PATH" == *"/dependencies/bash-create-onion-domains" ]]; then
    # This module is a dependency of another module.
    dependency_or_parent_path=".."
  else
    dependency_or_parent_path="dependencies"
  fi
  echo "dependency_or_parent_path=$dependency_or_parent_path"
  load_required_dependencies "$dependency_or_parent_path"
  load_parent_dependencies "$dependency_or_parent_path"
}

function load_required_dependency() {
  local dependency_or_parent_path="$1"
  local dependency_name="$2"
  local dependency_dir="$START_TOR_AT_BOOT_PATH/$dependency_or_parent_path/$dependency_name"
  echo "dependency_dir=$dependency_dir"
  if [ ! -d "$dependency_dir" ]; then
    echo "ERROR: $dependency_dir is not found in required dependencies."
    exit 1
  fi
  source "$dependency_dir/src/main.sh"
}

function load_required_dependencies() {
  local dependency_or_parent_path="$1"
  local required_dependencies=("bash-log" "bash-package-installer")
  # Iterate through dependencies and check if they exist and load them.
  for required_dependency in "${required_dependencies[@]}"; do
    load_required_dependency "$dependency_or_parent_path" "$required_dependency"
  done
}

function load_parent_dependencies() {
  local dependency_or_parent_path="$1"
  local parent_dependencies=("bash-start-tor-at-boot" "bash-ssh-over-tor")
  # Iterate through dependencies and check if they exist and load them.
  for parent_dep in "${parent_dependencies[@]}"; do
    local parent_dep_dir="$START_TOR_AT_BOOT_PATH/../$parent_dep"
    echo "parent_dep_dir=$parent_dep_dir"
    # Check if the parent repo above the dependency dir is the parent dependency.
    if [ ! -d "$START_TOR_AT_BOOT_PATH/../$parent_dep" ]; then
      # Must load the dependency as any other fellow dependency if it is not
      # a parent dependency.
      load_required_dependency "$dependency_or_parent_path" "$required_dependency"
    else
      # Load the parent dependency.
      # shellcheck disable=SC1090
      source "$START_TOR_AT_BOOT_PATH/../$parent_dep/src/main.sh"
    fi

  done
}

load_dependencies
LOG_LEVEL_ALL # set log level to all, otherwise, NOTICE, INFO, DEBUG, TRACE will not be logged.
B_LOG --file log/multiple-outputs.txt --file-prefix-enable --file-suffix-enable

# Load prerequisites installation.
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
