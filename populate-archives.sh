#!/bin/bash -ex
#
# mirror /srv/releases into archives.jenkins-ci.org
#
# exec to ensure that signals are propagated to child process
exec ssh mirrorsync@archives.jenkins-ci.org "mirrorsync"
