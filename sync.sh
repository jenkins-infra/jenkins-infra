#!/bin/bash -xe
HOST=jenkins@ftp-osl.osuosl.org
BASE_DIR=/srv/releases/jenkins
UPDATES_DIR=/var/www/updates.jenkins.io
REMOTE_BASE_DIR=data/
RSYNC_ARGS="-rlpgoDvz"
SCRIPT_DIR=$PWD
FLAG="${1}"

pushd $BASE_DIR
  time rsync ${RSYNC_ARGS} --times --delete-during --delete-excluded --prune-empty-dirs --include-from=<(
    # keep all the plugins
    echo '+ plugins/**'
    echo '+ updates/**'
    echo '+ art/**'
    echo '+ podcast/**'
    # I think this is a file we create on OSUOSL so dont let that be deleted
    echo '+ TIME'
    # copy all the symlinks
    find . -type l | sed -e 's#\./#+ /#g'
    # files that are older than last one year is removed from the mirror
    find . -type f -mtime +365 | sed -e 's#\./#- /#g'
    # the rest of the rules come from rsync.filter
    cat $SCRIPT_DIR/rsync.filter
  ) . $HOST:jenkins/
popd

echo ">> Syncing the update center to our local mirror"

pushd ${UPDATES_DIR}
    # Note: this used to exist in the old script, but we have these
    # symbolic links in the destination tree, no need to copy them again
    #
    #rsync ${RSYNC_ARGS}  *.json* ${BASE_DIR}/updates
    for uc_version in */update-center.json; do
      echo ">> Syncing UC version ${uc_version}"
      uc_version=$(dirname $uc_version)
      rsync ${RSYNC_ARGS} $uc_version/*.json* ${BASE_DIR}/updates/${uc_version}
    done;

    # Ensure that our tool installers get synced
    rsync ${RSYNC_ARGS}  updates ${BASE_DIR}/updates/

    echo ">> Syncing UC to primarily OSUOSL mirror"
    rsync ${RSYNC_ARGS} --delete ${BASE_DIR}/updates/ ${HOST}:jenkins/updates
popd

echo ">> Delivering bits to fallback"
/srv/releases/populate-archives.sh
/srv/releases/batch-upload.bash || true

echo ">> Updating the latest symlink for weekly"
/srv/releases/update-latest-symlink.sh
echo ">> Updating the latest symlink for weekly RC"
/srv/releases/update-latest-symlink.sh "-rc"
echo ">> Updating the latest symlink for LTS"
/srv/releases/update-latest-symlink.sh "-stable"
echo ">> Updating the latest symlink for LTS RC"
/srv/releases/update-latest-symlink.sh "-stable-rc"

echo ">> Triggering remote mirroring script"
ssh $HOST "sh trigger-jenkins"

echo ">> move index from staging to production"
# Excluding some files which the packaging repo which are now managed by Puppet
# see INFRA-985, INFRA-989
(cd /var/www && rsync --omit-dir-times -av \
    --exclude=.htaccess --exclude=jenkins.repo \
    pkg.jenkins.io.staging/ pkg.jenkins.io/)

if [ "${FLAG}" = '--full-sync' ]; then
  echo ">> Update artifacts on get.jenkins.io"
  source /srv/releases/.azure-storage-env
  source /srv/releases/.venv-blobxfer/bin/activate
  /usr/local/bin/blobxfer upload --storage-account "$AZURE_STORAGE_ACCOUNT" --storage-account-key "$AZURE_STORAGE_KEY" --local-path "$BASE_DIR" --remote-path mirrorbits --recursive --mode file --file-md5  --skip-on-md5-match --progress-bar --include "*.json" 2>&1
  time /usr/local/bin/blobxfer upload --storage-account "$AZURE_STORAGE_ACCOUNT" --storage-account-key "$AZURE_STORAGE_KEY" --local-path "$BASE_DIR" --remote-path mirrorbits --recursive --mode file --no-overwrite --exclude 'mvn%20org.apache.maven.plugins:maven-release-plugin:2.5:perform' --transfer-threads 128  --no-progress-bar 2>&1
fi
