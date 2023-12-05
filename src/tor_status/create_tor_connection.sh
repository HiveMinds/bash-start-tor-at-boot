#!/bin/bash
start_tor_in_background() {
  local wait_time_sec=260

  sudo tor | tee "$TOR_LOG_FILEPATH" >/dev/null &
  start_time=$(date +%s)

  while true; do
    error_substring='\[err\]'
    if [ "$(file_contains_string "$error_substring" "$TOR_LOG_FILEPATH")" == "FOUND" ]; then
      INFO "$TOR_LOG_FILEPATH contained: $error_substring, so we are stopping it and restarting it."
      kill_tor_if_already_running
      sleep 5
      INFO "Tor is stopped, starting it again."
      sudo tor | tee "$TOR_LOG_FILEPATH" >/dev/null &
    else
      NOTICE "The $TOR_LOG_FILEPATH did not contain: $error_substring, so we are checking the tor status."
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
    sleep 5
  done

}

# Running sudo tor is something else than ensuring the tor service runs at
# boot.Both are required for one to be able to ssh into the device over tor.
function ensure_tor_package_runs_at_boot() {
  local root_repo_path="$1"
  local relative_script_path="dependencies/bash-start-tor-at-boot/src/tor_status/create_tor_connection.sh"
  local absolute_script_path="$root_repo_path/$relative_script_path"
  manual_assert_file_exists "$absolute_script_path"

  local crontab_line
  crontab_line="@reboot /bin/bash $absolute_script_path && start_tor_in_background"
  # Add entry to cron to execute the script at boot
  # Check if the line already exists in crontab
  if ! crontab -l | grep -q "$crontab_line"; then
    # If the line doesn't exist, add it to crontab
    (
      crontab -l 2>/dev/null
      echo "$crontab_line"
    ) | crontab -
    NOTICE "ADDING ENTRY to crontab."
  else
    NOTICE "Entry already exists in crontab."
  fi

  # Ensure the crontab contains the entry.
  if [[ "$(crontab -l | grep "$crontab_line")" == "" ]]; then
    ERROR "The crontab did not contain the entry: $crontab_line"
    exit 1
  fi

  # TODO: verify the contrab contains the entry once.
  # if [[ "$(crontab -l | grep "$absolute_script_path" | wc -l)" != "1" ]]; then
  if [[ "$(crontab -l | grep -c "$crontab_line")" != "1" ]]; then
    ERROR "The crontab contained the entry: $crontab_line more than once."
    exit 1
  fi

  # Define the variables
  local systemd_service_unit_path="/etc/systemd/system/tor_startup.service"

  # Store the content in a variable
  local systemd_service_unit_content
  systemd_service_unit_content=$(
    cat <<EOF
[Unit]
Description=Start Tor at boot

[Service]
Type=simple
ExecStart=/bin/bash $absolute_script_path

[Install]
WantedBy=multi-user.target
EOF
  )

  # Add the content to the specified file path
  echo "$systemd_service_unit_content" | sudo tee "$systemd_service_unit_path" >/dev/null

  # Verify the file content is as expected.
  assert_file_content_equal "$systemd_service_unit_path" "$systemd_service_unit_content"

  # Enable the systemd service
  sudo systemctl enable tor_startup.service

  NOTICE "Setup complete. Script:$absolute_script_path will run at boot."

}
