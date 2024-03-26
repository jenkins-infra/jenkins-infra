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
source /srv/releases/.azure-storage-env
: "${AZURE_STORAGE_ACCOUNT?}" "${AZURE_STORAGE_KEY?}" "${STORAGE_NAME?}" "${STORAGE_FILESHARE?}"

RECENT_RELEASES=$( jq --raw-output '.releases[] | .name + "/" + .version' "${RECENT_RELEASES_JSON}" )
if [[ -z "${RECENT_RELEASES}" ]] ; then
    echo "No recent releases"
    exit
fi

echo "${RECENT_RELEASES}"
echo

export STORAGE_DURATION_IN_MINUTE=5
export STORAGE_PERMISSIONS=dlrw

# Don't print any trace
set +x

fileShareSignedUrl=$(get-fileshare-signed-url.sh)
urlWithoutToken=${fileShareSignedUrl%\?*}
token=${fileShareSignedUrl#*\?}

while IFS= read -r release; do
    # Ensure proper permissions are set (mirrorbrain is the owner and can write while www-data only need read access for webserver)
    find "${BASE_DIR}/plugins/${release}" -exec chown mirrorbrain:www-data {} \;
    find "${BASE_DIR}/plugins/${release}" -type f -exec chmod 644 {} \;
    find "${BASE_DIR}/plugins/${release}" -type d -exec chmod 755 {} \;

    echo "Uploading ${release} to get.jenkins.io..."
    # Don't print any trace
    set +x
    ## azcopy breaks the while + read loop - https://github.com/Azure/azure-storage-azcopy/issues/974
    ## so we ensure an empty stding is passed using the ':|' form
    : | azcopy copy \
        --skip-version-check `# Do not check for new azcopy versions (we have updatecli + puppet for this)` \
        --recursive `# Source directory contains at least one subdirectory` \
        --log-level=ERROR `# Do not write too much logs (I/O...)` \
        "${BASE_DIR}/plugins/${release}/*" "${urlWithoutToken}plugins/${release}?${token}"

    # Following commands traces are safe
    set -x
    echo "Done uploading ${release} to get.jenkins.io"

    echo "Uploading ${release} to OSUOSL..."
    ssh -n "${HOST}" "mkdir -p jenkins/plugins/${release}"
    rsync -rlptDvz --chown=jenkins "${BASE_DIR}/plugins/${release}/" "${HOST}:jenkins/plugins/${release}"
    date +%s > "${BASE_DIR}/TIME"
    rsync -rlptDvz --chown=jenkins "${BASE_DIR}/TIME" "${HOST}:jenkins/TIME"
    echo "Done uploading ${release} to OSUOSL"
done <<< "${RECENT_RELEASES}"

# Following commands traces are safe
set -x

echo ">> Telling OSUOSL to gets the new bits"
ssh jenkins@ftp-osl.osuosl.org 'sh trigger-jenkins'

echo ">> Delivering bits to mirrors fallback (archives.jenkins.io) from OSUOSL"
/srv/releases/populate-archives.sh
