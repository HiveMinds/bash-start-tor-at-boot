#!/bin/bash
start_tor_in_background() {
  working_dir="$1"
  # If working dir is not empty and does not end in a slash, add it.
  if [[ "$working_dir" != "" ]] && [[ "${working_dir: -1}" != "/" ]]; then
    working_dir="$working_dir/"
  fi
  local wait_time_sec=260

  NOTICE "Starting tor in the background. Logging into:$working_dir$TOR_LOG_FILENAME"
  tor | tee "$working_dir$TOR_LOG_FILENAME" >/dev/null &

  start_time=$(date +%s)

  while true; do
    error_substring='\[err\]'
    error_substring_two='[err]'
    if [ "$(file_contains_string "$error_substring" "$working_dir$TOR_LOG_FILENAME")" == "FOUND" ]; then
      INFO "$working_dir$TOR_LOG_FILENAME contained: $error_substring, so we are stopping it and restarting it."
      read -rp "the content of the file is: $(cat "$working_dir$TOR_LOG_FILENAME"). Press enter to continue."
      kill_tor_if_already_running
      sleep 5
      NOTICE "Retry starting tor."
      tor | tee "$working_dir$TOR_LOG_FILENAME" >/dev/null &
    if [ "$(file_contains_string "$error_substring_two" "$working_dir$TOR_LOG_FILENAME")" == "FOUND" ] || [ "$(file_contains_string "$error_substring_two" "$working_dir$TOR_LOG_FILENAME")" == "FOUND" ]; then
      INFO "$working_dir$TOR_LOG_FILENAME contained: $error_substring_two, so we are stopping it and restarting it."
      read -rp "the content of the file is: $(cat "$working_dir$TOR_LOG_FILENAME"). Press enter to continue."
      kill_tor_if_already_running
      sleep 5
      NOTICE "Retry starting tor."
      tor | tee "$working_dir$TOR_LOG_FILENAME" >/dev/null &
    else
      NOTICE "The $working_dir$TOR_LOG_FILENAME did not contain: $error_substring, so we are checking the tor status."
      local tor_status
      tor_status="$(tor_is_connected)"
      INFO "tor_status=$tor_status"
      if [[ "$(tor_is_connected)" == "FOUND" ]]; then
        NOTICE "Successfully setup tor connection."
        return 0
      else
        INFO "Tor was not found to be connected. Re-starting the loop."
        sleep 1
      fi
    fi
    sleep 1

    # Calculate the elapsed time from the start of the function
    elapsed_time=$(($(date +%s) - start_time))

    # If wait_time_sec seconds have passed, raise an exception and return 6.
    if ((elapsed_time > wait_time_sec)); then
      kill_tor_if_already_running
      ERROR "Error: a tor connection was not created after $wait_time_sec seconds."
      exit 6
    fi
    INFO "Waiting another 5 seconds before checking the tor status again."

    # Wait for 5 seconds before checking again.
    sleep 20
  done

}
