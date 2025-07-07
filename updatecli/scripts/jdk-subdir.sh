#!/bin/bash

set -eu -o pipefail

if [ $# -eq 0 ]; then
    echo "this script need a jdk download url"
    exit 1
fi

command -v curl >/dev/null 2>&1 || { echo "ERROR: curl command not found. Exiting."; exit 1; }
command -v tar >/dev/null 2>&1 || { echo "ERROR: tar command not found. Exiting."; exit 1; }

DOWNLOAD_URL="$1"

MAIN_FOLDER=$(curl --location --silent "$DOWNLOAD_URL" | tar --list --gzip | head -1 | cut -d'/' -f1)
echo "${MAIN_FOLDER}"
