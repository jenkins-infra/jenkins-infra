#!/bin/bash -xe
HOST=jenkins@ftp-osl.osuosl.org
BASE_DIR=/srv/releases/jenkins
UPDATES_DIR=/var/www/updates.jenkins.io
REMOTE_BASE_DIR=data/
RSYNC_ARGS="-rlpgoDvz"
SCRIPT_DIR=$PWD

pushd $BASE_DIR
  rsync ${RSYNC_ARGS} --times --delete-during --delete-excluded --prune-empty-dirs --include-from=<(
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
/srv/releases/batch-upload.bash

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
    --exclude=.htaccess --exclude=\*.key --exclude=jenkins.repo \
    pkg.jenkins.io.staging/ pkg.jenkins.io/)

# This section of the script aims to ensure that at least one of our primary mirrors has the
# "big" archives before we complete execution. This will help prevent users from unexpectedly
# hitting fallback mirrors when our primary mirrors *have* the data and we simply haven't updated
# our indexes
#
# https://issues.jenkins-ci.org/browse/INFRA-483
echo ">> Sleeping to allow the OSUOSL to propogate some bits"
sleep 120

echo ">> attempting to update indexes with released archive"
for f in debian debian-stable redhat redhat-stable war war-stable opensuse opensuse-stable osx osx-stable windows windows-stable updates; do
  echo ">>>> updating index for ${f}/"
  mb scan -j 2 -v -d $f -e ftp-chi.osuosl.org;
done


