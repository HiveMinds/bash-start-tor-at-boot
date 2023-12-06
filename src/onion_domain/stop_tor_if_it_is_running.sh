#!/bin/bash

kill_tor_if_already_running() {
  local output
  local normal_tor_closed
  local sudo_tor_closed
  while true; do
    output=$(netstat -ano | grep LISTEN | grep 9050)
    INFO "netstat output=$output"
    if [[ "$output" != "" ]]; then
      sudo killall tor
      # TODO: move into stopping equivalent of ensure_service_is_started.
      sudo systemctl stop tor
      normal_tor_closed="false"
      INFO "Killed and stopped tor, because there was a non-tor instance running."
      sleep 2

    else
      NOTICE "non-tor is killed and stopped."
      normal_tor_closed="true"
    fi

    sudo_output=$(sudo netstat -ano | grep LISTEN | grep 9050)
    INFO "SUDO netstat output=$output"
    if [[ "$sudo_output" != "" ]]; then
      # sudo kill -9 `pidof tor`
      sudo killall tor
      sudo systemctl stop tor
      sudo_tor_closed="false"
      INFO "Killed and stopped tor, because there was a tor instance running."
      sleep 2
    else
      NOTICE "tor is killed and stopped."
      sudo_tor_closed="true"
    fi
    if [[ "$normal_tor_closed" == "true" ]] && [[ "$sudo_tor_closed" == "true" ]]; then
      NOTICE "Both non-sudo and tor are stopped."
      return 0
    fi
  done
}

assert_tor_is_not_running() {
  local output
  ensure_apt_pkg "net-tools" 1 # Required to run netstat.
  output=$(netstat -ano | grep LISTEN | grep 9050)
  if [[ "$output" != "" ]]; then
    echo "ERROR, tor/something is still running on port 9050:$output"
    exit 6
  fi

}
