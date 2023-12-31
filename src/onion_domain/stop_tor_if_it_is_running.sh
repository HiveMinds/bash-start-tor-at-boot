#!/bin/bash

function kill_tor_if_already_running() {
  local socks_port="$1"
  assert_is_non_empty_string "$socks_port"
  local output
  local normal_tor_closed
  while true; do
    output=$(netstat -ano | grep LISTEN | grep "$socks_port")
    if [[ "$output" != "" ]]; then
      killall tor
      echo "Killed and stopped tor, because there was a tor instance running."
      sleep 2
    else
      NOTICE "Non-sudo tor is killed and stopped."
      normal_tor_closed="true"
    fi

    if [[ "$normal_tor_closed" == "true" ]]; then
      NOTICE "Both non-sudo tor is stopped."
      return 0
    fi
  done
}

assert_tor_is_not_running() {
  local output
  assert_is_non_empty_string "$SOCKS_PORT"
  ensure_apt_pkg "net-tools" 1 # Required to run netstat.
  output=$(netstat -ano | grep LISTEN | grep $SOCKS_PORT)
  if [[ "$output" != "" ]]; then
    ERROR "ERROR, tor/something is still running on port $SOCKS_PORT:$output"
    exit 6
  fi

}
