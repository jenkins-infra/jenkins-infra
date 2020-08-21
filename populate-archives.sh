#!/bin/bash -ex
#
# mirror /srv/releases into archives.jenkins-ci.org
#
exec rsync -avz /srv/releases/jenkins/ www-data@archives.jenkins-ci.org:/srv/releases/
