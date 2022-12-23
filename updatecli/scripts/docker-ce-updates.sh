#!/bin/bash
set -eu -o pipefail

if ! command -v docker >/dev/null 2>&1
then
  echo "ERROR: command line 'docker' required but not found. Exiting."
  exit 1
fi

SCRIPT_PATH=$(dirname "$0")
SCRIPT_PATH=$(cd "$SCRIPT_PATH" && pwd)

docker run --rm --name=updatecli-docker-ce --volume="$SCRIPT_PATH":/scripts/ --entrypoint=bash ubuntu:"${1}" /scripts/fetch-docker-ce-latest-version.sh
