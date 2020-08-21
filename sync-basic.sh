#!/usr/bin/env bash
set -xe

HOST=jenkins@ftp-osl.osuosl.org
BASE_DIR=/srv/releases/jenkins
UPDATES_DIR=/var/www/updates.jenkins.io
REMOTE_BASE_DIR=data/
SCRIPT_DIR=$PWD
FLAG="${1}"

echo ">> Update artifacts on get.jenkins.io"

source /srv/releases/.azure-storage-env
RECENT_RELEASES=$(cat ${UPDATES_DIR}/experimental/recent-releases.json | jq -r '.releases[] | .name + "/" + .version')
while IFS= read -r release; do
     blobxfer upload --storage-account "$AZURE_STORAGE_ACCOUNT" --storage-account-key "$AZURE_STORAGE_KEY" --local-path "${BASE_DIR}/plugins/$release" --remote-path mirrorbits/plugins/${release} --recursive --mode file --no-overwrite --exclude 'mvn%20org.apache.maven.plugins:maven-release-plugin:2.5:perform' --file-md5 --skip-on-md5-match  --no-progress-bar
done <<< "${RECENT_RELEASES}"

