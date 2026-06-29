#!/bin/bash
# Avoid debug mode (as it would print the secret value to stderr)
set -eu -o pipefail

secrets_host_dir=/var/run/jenkins-secrets
# TODO: move to puppet to avoid having to write the custom GID of the "jenkins" group in advance
owners="root:1001"

mkdir -p "${secrets_host_dir}"

chown "${owners}" "${secrets_host_dir}"
chmod 0750 "${secrets_host_dir}"

for secret in "$@"
do
  secret_file="${secrets_host_dir}"/"${secret}"
  touch "${secret_file}"
  chown "${owners}" "${secret_file}"
  chmod 0640 "${secret_file}"

  echo "${!secret}" > "${secret_file}"
done
