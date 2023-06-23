#!/bin/bash

set -eux -o pipefail

current_dir="$(cd "$(dirname "$0")" && pwd -P)"
repo_dir="$(cd "${current_dir}"/.. && pwd -P)"

echo "> Checking for additional tools version to help debugging (or fail fast)..."
vagrant -v
docker -v

echo "> Installing Development Dependencies (Gems, etc.)..."
bash "${current_dir}/setupgems.sh"
pushd "${repo_dir}/"
rm -rf "./modules"
ln -s  "./spec/fixtures/modules" "./modules" # Reuse modules from rpsec tests
popd

echo "> Prebuilding the Docker image to ensure it is kept in cache (by giving a name)"
docker build -t jenkins-infra-ubuntu:22.04 "${repo_dir}/vagrant-docker/"
