#!/bin/bash
# To simplify the code that runs from a cronjob which starts tor at boot, this
# is a self-contained bash script that starts tor, without sudo, in the
# background, and checks whether it is connected to the tor network.

# List of used functions:
# file_contains_string
# kill_tor_if_already_running
# tor_is_connected
#   self_contained_get_tor_status
TOR_LOG_FILENAME="tor.log"
SCRIPT_LOG="tor_script.log"
self_contained_start_tor_in_background() {
  local socks_port="$1"
  local working_dir="$2"
  # If working dir is not empty and does not end in a slash, add it.
  if [[ "$working_dir" != "" ]] && [[ "${working_dir: -1}" != "/" ]]; then
    working_dir="$working_dir/"
  fi
  local wait_time_sec=260

  echo "Starting tor in the background. Logging into:$working_dir$TOR_LOG_FILENAME" >>"$working_dir$SCRIPT_LOG"
  tor | tee "$working_dir$TOR_LOG_FILENAME" >/dev/null &

  start_time=$(date +%s)

  while true; do
    error_substring='\[err\]'
    if [ "$(file_contains_string "$error_substring" "$working_dir$TOR_LOG_FILENAME")" == "FOUND" ]; then
      echo "$working_dir$TOR_LOG_FILENAME contained: $error_substring, so we are stopping it and restarting it." >>"$working_dir$SCRIPT_LOG"
      self_contained_kill_tor_if_already_running "$socks_port" "$working_dir"
      sleep 5
      echo "Retry starting tor." >>"$working_dir$SCRIPT_LOG"
      tor | tee "$working_dir$TOR_LOG_FILENAME" >/dev/null &
    else
      echo "The $working_dir$TOR_LOG_FILENAME did not contain: $error_substring, so we are checking the tor status." >>"$working_dir$SCRIPT_LOG "
      local tor_status
      tor_status="$(self_contained_tor_is_connected "$socks_port" $"$working_dir")"
      echo "tor_status=$tor_status" >>"$working_dir$SCRIPT_LOG "
      if [[ "$(self_contained_tor_is_connected "$socks_port" $"$working_dir")" == "FOUND" ]]; then
        echo "Successfully setup tor connection." >>"$working_dir$SCRIPT_LOG "
        return 0
      else
        echo "Tor was not found to be connected. Re-starting the loop." >>"$working_dir$SCRIPT_LOG "
        sleep 1
      fi
    fi
    sleep 1

    # Calculate the elapsed time from the start of the function
    elapsed_time=$(($(date +%s) - start_time))

    # If wait_time_sec seconds have passed, raise an exception and return 6.
    if ((elapsed_time > wait_time_sec)); then
      self_contained_kill_tor_if_already_running "$socks_port" "$working_dir"
      ERROR "Error: a tor connection was not created after $wait_time_sec seconds."
      exit 6
    fi
    echo "Waiting another 5 seconds before checking the tor status again." >>"$working_dir$SCRIPT_LOG "

    # Wait for 5 seconds before checking again.
    sleep 20
  done

}

#######################################
#
# Local variables:
#
# Globals:
#  None.
# Arguments:
#
# Returns:
#  0 if
#  7 if
# Outputs:
#  None.
#######################################
# Structure:Parsing
# allows a string with spaces, hence allows a line
file_contains_string() {
  local some_string="$1"
  local relative_filepath="$2"
  if grep -q "$some_string" "$relative_filepath"; then
    echo "FOUND"
  else
    echo "NOTFOUND"
  fi
}

self_contained_kill_tor_if_already_running() {
  local socks_port="$1"
  local working_dir="$2"

  local output
  local normal_tor_closed
  while true; do
    output=$(netstat -ano | grep LISTEN | grep "$socks_port")
    echo "netstat output=$output" >>"$working_dir$SCRIPT_LOG"
    if [[ "$output" != "" ]]; then
      killall tor
      echo "Killed and stopped tor, because there was a tor instance running." >>"$working_dir$SCRIPT_LOG "
      sleep 2
    else
      echo "Non-sudo tor is killed and stopped." >>"$working_dir$SCRIPT_LOG "
      normal_tor_closed="true"
    fi

    if [[ "$normal_tor_closed" == "true" ]]; then
      echo "Both non-sudo tor is stopped." >>"$working_dir$SCRIPT_LOG"
      return 0
    fi
  done
}

self_contained_tor_is_connected() {
  local socks_port="$1"
  local working_dir="$2"
  local tor_status_outside
  tor_status_outside="$(self_contained_get_tor_status "$socks_port" "$working_dir")"
  # Reconnect tor if the system is disconnected.
  if [[ "$tor_status_outside" != *"Congratulations"* ]]; then
    echo "NOTFOUND"
  elif [[ "$tor_status_outside" == *"Congratulations"* ]]; then
    echo "FOUND"
  fi
}

self_contained_get_tor_status() {
  local socks_port="$1"
  local working_dir="$2"
  local tor_status
  tor_status="$(curl --socks5 localhost:"$socks_port" --socks5-hostname localhost:"$socks_port" -s https://check.torproject.org/ | cat | grep -m 1 Congratulations | xargs)"
  echo "$tor_status"
}

function get_socket_port() {
  local torrc_file="/etc/tor/torrc" # Replace this with the path to your torrc file
  local socket_port

  if [[ -f "$torrc_file" ]]; then
    socket_port=$(awk '/^SocksPort/ {print $2}' "$torrc_file")
    if [[ -z "$socket_port" ]]; then
      socket_port="9050"
    fi
  else
    socket_port="9050"
  fi
  echo "$socket_port"
}

# Parse the CLI argument
WORKING_DIR="$1"
shift # Eat CLI arg.
SOCKS_PORT="$(get_socket_port)"

# Raise exception if working dir is empty.
if [[ "$WORKING_DIR" == "" ]]; then
  echo "Error, the working dir was empty."
  echo "Error, the working dir was empty." >>"$(whoami)/ERROR_IN_TOR_LOG.txt"
  exit 1
fi
self_contained_start_tor_in_background "$SOCKS_PORT" "$WORKING_DIR"
echo "DONE" >"$WORKING_DIR/$SCRIPT_LOG.txt"
