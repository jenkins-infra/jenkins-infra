#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail

BASE_DIR=/srv/releases/jenkins
HOST=jenkins@ftp-osl.osuosl.org

[[ $# -eq 1 ]] || { echo "Usage: $0 <recent-releases.json>" >&2 ; exit 1 ; }
[[ -f "$1" ]] || { echo "$1 is not a file" >&2 ; exit 2 ; }
RECENT_RELEASES_JSON="$1"


echo ">> Update artifacts on get.jenkins.io"

#shellcheck disable=SC1091
source /srv/releases/.venv-blobxfer/bin/activate
#shellcheck disable=SC1091
source /srv/releases/.azure-storage-env

RECENT_RELEASES=$( jq --raw-output '.releases[] | .name + "/" + .version' "$RECENT_RELEASES_JSON" )
if [[ -z "$RECENT_RELEASES" ]] ; then
    echo "No recent releases"
    exit
fi

echo "$RECENT_RELEASES"
echo

while IFS= read -r release; do
    echo "Uploading $release"

    blobxfer upload --storage-account "$AZURE_STORAGE_ACCOUNT" --storage-account-key "$AZURE_STORAGE_KEY" --local-path "${BASE_DIR}/plugins/$release" --remote-path mirrorbits/plugins/"${release}" --recursive --mode file --no-overwrite --exclude 'mvn%20org.apache.maven.plugins:maven-release-plugin:2.5:perform' --file-md5 --skip-on-md5-match  --no-progress-bar

    ssh -n ${HOST} "mkdir -p jenkins/plugins/${release}"

    rsync -avz ${BASE_DIR}/plugins/"${release}"/ ${HOST}:jenkins/plugins/"${release}"
    date +%s > ${BASE_DIR}/TIME
    rsync -avz ${BASE_DIR}/TIME ${HOST}:jenkins/TIME
    echo "Done uploading $release"
done <<< "${RECENT_RELEASES}"

echo ">> Delivering bits to fallback"
/srv/releases/populate-archives.sh

echo ">> Telling OSUUSL to gets the new bits"
ssh jenkins@ftp-osl.osuosl.org 'sh trigger-jenkins'
