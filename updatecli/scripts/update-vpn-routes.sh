#!/bin/bash

set -eu -o pipefail

vpn_image_version="${1}"
route_type="${2}"
result=""

{
  set -x # E
  vpn_config_url="https://raw.githubusercontent.com/jenkins-infra/docker-openvpn/refs/tags/${vpn_image_version}/config.yaml"

  command -v yq >/dev/null || { echo "ERROR: command 'yq' not found in your PATH."; exit 1;}

  vpn_config="$(curl --fail --location --silent --show-error "${vpn_config_url}" --output -)"
  routes="$(echo "${vpn_config}" | yq '.networks.private.routes')"

  if [ "${route_type}" == "servers" ]
  then
    ## Extract routes with a /32 which maps to single servers
    ## Note: may be multi-valued (separator is space: ' ')
    server_routes="$(echo "${routes}" \
      | grep '/32' `# Only keep lines which contains the /32 mask` \
      | sort -u `# Sort them to ensure deterministic behavior` \
      | sed 's#/32##g' `# Remove all occurrences of '/32'` \
    )"
    # Now we build a new YAML line by line to match the expected format
    # for the hierdaata 'profile::openvpn::external_ips_vpn_restricted' property
    server_routes_yaml=""
    while IFS= read -r line
    do
      route_name="$(echo "${line}" | cut -d':' -f1)"
      route_str_value="$(echo "${line}" | cut -d':' -f2)"
      # Split the value with default separator (space) to determine how many IPs are present
      route_values=()
      read -r -a route_values <<< "${route_str_value}"
      length=${#route_values[@]}
      if [ "${length}" -gt 1 ]
      then
        # When dealing with many IPs, the route name is appended with "_X"
        # where X is the 1-index (e.g. no zero) number
        for (( j=0; j<"$length"; j++ ));
        do
          key="${route_name}_$((j+1))"
          value="${route_values[$j]}"
          # Append resulting route line into the YAML map we're building
          server_routes_yaml+=$(printf '%s: %s' "$key" "$value")$'\n'
        done
      else
        key="${route_name}"
        # Remove whitespaces characters
        value="${route_str_value#[[:space:]]}"
        # Append resulting route line into the YAML map we're building
        server_routes_yaml+=$(printf '%s: %s' "$route_name" "${route_str_value#[[:space:]]}")$'\n'
      fi
    done <<< "${server_routes}"

    yaml_target=./hieradata/common.yaml
    result="$(echo "${server_routes_yaml}" | yq eval-all \
    'select(fileIndex == 1) as $routes 
    | select(fileIndex == 0)
    | .["profile::openvpn::external_ips_vpn_restricted"] = $routes
    | .["profile::openvpn::image_tag"] = "'"${vpn_image_version}"'"' \
    "${yaml_target}" -)"
  else
    # Extract network routes (without a /32) mapping to internal peered vnet or subnets
    network_routes="$(echo "${routes}" \
      | grep -v '/32' `# Remove lines which contains the /32 mask` \
      | sort -u `# Sort them to ensure deterministic behavior` \
    )"
    yaml_target=./hieradata/clients/private.vpn.jenkins.io.yaml
    result="$(echo "${network_routes}" | yq eval-all \
      'select(fileIndex == 1) as $routes | select(fileIndex == 0) | .["profile::openvpn::networks"].eth1.peered_network_cidrs = $routes' \
      "${yaml_target}" -)"
  fi
} 1>&2

echo "${result}" && echo
