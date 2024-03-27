#!/bin/bash -xe
HOST=jenkins@ftp-osl.osuosl.org
BASE_DIR=/srv/releases/jenkins
UPDATES_DIR=/var/www/updates.jenkins.io
RSYNC_ARGS="-rlpDvz"
SCRIPT_DIR=${PWD}
FLAG="${1}"

pushd "${BASE_DIR}"
  time rsync "${RSYNC_ARGS}" --chown=jenkins --times --delete-during --delete-excluded --prune-empty-dirs --include-from=<(
    # keep all the plugins
    echo '+ plugins/**'
    echo '+ updates/**'
    echo '+ art/**'
    echo '+ podcast/**'
    # I think this is a file we create on OSUOSL so dont let that be deleted
    echo '+ TIME'
    # copy all the symlinks
    #shellcheck disable=SC2312
    find . -type l | sed -e 's#\./#+ /#g'
    # files that are older than last one year is removed from the mirror
    #shellcheck disable=SC2312
    find . -type f -mtime +365 | sed -e 's#\./#- /#g'
    # the rest of the rules come from rsync.filter
    #shellcheck disable=SC2312
    cat "${SCRIPT_DIR}/rsync.filter"
  ) . "${HOST}:jenkins/"
popd

echo ">> Syncing the update center to our local mirror"

pushd "${UPDATES_DIR}"
    # Note: this used to exist in the old script, but we have these
    # symbolic links in the destination tree, no need to copy them again
    #
    #rsync ${RSYNC_ARGS}  *.json* ${BASE_DIR}/updates
    for uc_version in */update-center.json; do
      echo ">> Syncing UC version ${uc_version}"
      uc_version=$(dirname "${uc_version}")
      rsync "${RSYNC_ARGS}" --chown=mirrorbrain:www-data "${uc_version}"/*.json* "${BASE_DIR}/updates/${uc_version}"
    done;

    # Ensure that our tool installers get synced
    rsync "${RSYNC_ARGS}" --chown=mirrorbrain:www-data updates "${BASE_DIR}/updates/"

    echo ">> Syncing UC to primarily OSUOSL mirror"
    rsync "${RSYNC_ARGS}" --chown=jenkins --delete "${BASE_DIR}/updates/" "${HOST}:jenkins/updates"
popd

echo ">> Delivering bits to fallback"
/srv/releases/populate-archives.sh || true

## Disabled as always failing since Feb. 2024
# /srv/releases/batch-upload.bash || true

echo ">> Updating the latest symlink for weekly"
/srv/releases/update-latest-symlink.sh
echo ">> Updating the latest symlink for weekly RC"
/srv/releases/update-latest-symlink.sh "-rc"
echo ">> Updating the latest symlink for LTS"
/srv/releases/update-latest-symlink.sh "-stable"
echo ">> Updating the latest symlink for LTS RC"
/srv/releases/update-latest-symlink.sh "-stable-rc"

echo ">> Triggering remote mirroring script"
ssh "${HOST}" "sh trigger-jenkins"

echo ">> move index from staging to production"
# Excluding some files which the packaging repo which are now managed by Puppet
# see INFRA-985, INFRA-989
(cd /var/www && rsync --chown=mirrorbrain:www-data --omit-dir-times -av \
    --exclude=.htaccess --exclude=jenkins.repo \
    pkg.jenkins.io.staging/ pkg.jenkins.io/)

if [[ "${FLAG}" = '--full-sync' ]]; then
  echo ">> Updating artifacts on get.jenkins.io..."

  # Don't print any trace
  set +x

  echo ">>> retrieving the file share URL..."
  #shellcheck disable=SC1091
  source /srv/releases/.azure-storage-env
  : "${AZURE_STORAGE_ACCOUNT?}" "${AZURE_STORAGE_KEY?}"

  export STORAGE_DURATION_IN_MINUTE=30 #TODO: to be adjusted
  export STORAGE_PERMISSIONS=dlrw

  fileShareSignedUrl="$(get-fileshare-signed-url.sh)"
  echo ">>> retrieved the file share URL"

  echo ">>> azcopy-ing the JSON files..."
  : | azcopy copy \
    --skip-version-check `# Do not check for new azcopy versions (we have updatecli + puppet for this)` \
    --recursive `# Source directory contains at least one subdirectory` \
    --overwrite=ifSourceNewer `# Only overwrite if source is more recent (time comparison)` \
    --log-level=ERROR `# Do not write too much logs (I/O...)` \
    --include-pattern='*.json' `# First quick pass on the update center JSON files` \
    "${BASE_DIR}/*" "${fileShareSignedUrl}"
  echo ">>> finished azcopy-ing the JSON files"

  echo ">>> azcopy-ing all the other files..."
  : | azcopy copy \
    --skip-version-check `# Do not check for new azcopy versions (we have updatecli + puppet for this)` \
    --recursive `# Source directory contains at least one subdirectory` \
    --overwrite=ifSourceNewer `# Only overwrite if source is more recent (time comparison)` \
    --log-level=ERROR `# Do not write too much logs (I/O...)` \
    --exclude-pattern='*.json' `# Second pass with all files except update center JSON files` \
    "${BASE_DIR}/*" "${fileShareSignedUrl}"
  echo ">>> finished azcopy-ing all the other files"
  
  # Back to debug mode
  set -x
  
  echo ">> finished updating artifacts on get.jenkins.io"

  echo ">> Cleanup..."
  # Remove completed azcopy plans
  azcopy jobs clean --with-status=completed
  # Remove uncompleted azcopy plans older than 30 days
  find "${HOME}"/.azcopy/plans -type f -mtime +30 -delete
  # Remove azcopy logs older than 30 days
  find "${HOME}"/.azcopy -type f -name '*.log' -mtime +30 -delete
  echo ">> Cleanup finished"
fi

echo ">> Script sync.sh finished"
exit 0
