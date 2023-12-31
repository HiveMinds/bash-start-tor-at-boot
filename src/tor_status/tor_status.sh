#!/bin/bash
get_tor_status() {
  local socks_port="$1"
  local working_dir="$2"
  local tor_status
  tor_status="$(curl --socks5 localhost:"$socks_port" --socks5-hostname localhost:"$socks_port" -s https://check.torproject.org/ | cat | grep -m 1 Congratulations | xargs)"
  echo "$tor_status"
}

tor_is_connected() {
  local socks_port="$1"
  local working_dir="$2"
  local tor_status_outside
  tor_status_outside="$(get_tor_status "$socks_port" "$working_dir")"
  # Reconnect tor if the system is disconnected.
  if [[ "$tor_status_outside" != *"Congratulations"* ]]; then
    echo "NOTFOUND"
  elif [[ "$tor_status_outside" == *"Congratulations"* ]]; then
    echo "FOUND"
  fi
}

# Returns "FOUND" if an onion was available on the first try.
# TODO: allow for retries in parsing ping output.
onion_address_is_available() {
  local onion_address="$1"

  local ping_output
  ping_output=$(torsocks httping --count 1 "$onion_address" 2>/dev/null)
  if [[ "$ping_output" == *"100,00% failed"* ]]; then
    echo "NOTFOUND"
  elif [[ "$ping_output" == *"1 connects, 1 ok, 0,00% failed, time"* ]]; then
    echo "FOUND"
  else
    ERROR "Error, did not find status."
    exit 5
  fi
}

assert_onion_address_is_available() {
  local project_name="$1"
  local use_https="$2"
  local public_port_to_access_onion="$3"

  local onion_address
  onion_address="$(get_onion_address "$project_name" "$use_https" "$public_port_to_access_onion")"
  NOTICE "onion_address=\n$onion_address"
  if [ "$(onion_address_is_available "$onion_address")" != "FOUND" ]; then
    ERROR "Error, was not able to connect to:$onion_address"
    exit 5
  fi

}

# TODO: make it fail if the hostname file that contains the onion does not exist.
# TODO: make it fail if the onion is not valid.
get_onion_domain() {
  local project_name="$1"
  local onion_exists
  onion_exists=$(check_onion_url_exists_in_hostname "$project_name")
  if [[ "$onion_exists" == "FOUND" ]]; then
    cat "$TOR_SERVICE_DIR/$project_name/hostname"
  else
    ERROR "Error, the onion url was not found in file."
    exit 6
  fi
}

get_onion_address() {
  local project_name="$1"
  local use_https="$2"
  local public_port_to_access_onion="$3"

  local onion_domain
  onion_domain="$(get_onion_domain "$project_name")"

  local onion_url
  if [[ "$use_https" == "true" ]]; then
    onion_url="https://$onion_domain"
  else
    onion_url="http://$onion_domain"
  fi

  local onion_address
  if [ "$public_port_to_access_onion" == "" ]; then
    onion_address="$onion_url"
  else
    onion_address="$onion_url:$public_port_to_access_onion"
  fi
  echo "$onion_address"
}

ssh_onion_is_available() {
  local onion_domain="$1"
  local public_port_to_access_onion="$2"

  # TODO: log the output of the below command to file with INFO "ssh_check_output=$COMMAND_OUTPUT"
  if torsocks nc -zv "$onion_domain" "$public_port_to_access_onion" >/dev/null 2>&1; then
    echo "FOUND"
  else
    echo "NOTFOUND"
  fi
}
