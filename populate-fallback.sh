#!/bin/bash -ex
# MANAGED BY PUPPET. DO NOT MODIFY
#
# put the recent files in the fallback mirror (and recent files alone)
# OSUOSL mirror system has a problem in that its behavior is asynchronous,
# meaning we don't know exactly when it starts serving new files. this creates
# a brief time window where files visible from http://pkg.jenkins-ci.org/ results in 404
# (because those files aren't yet available from OSUOSL mirrors.)
#
# To prevent this problem, we create a fallback mirror under our control on http://fallback.jenkins-ci.org/
# where we can synchronously push files. Because this fallback mirror is only expected to serve
# very new files, this script only copies those files that are created within last 7 days.
# In this way, we keep the disk consumption in check
#
cd /srv/releases/jenkins
rsync -avz --delete-during --delete-excluded --prune-empty-dirs --include-from=<(
  # no .htaccess
  echo '- .htaccess'
  # files that are modified within the last 7 days
  (find . -type f -mtime -7) | sed -e 's#\./#+ /#g'
  # skip updates/ directory
  echo '- updates/'
  # visit all directories
  echo '+ */'
  # exclude everything else
  echo '- *'
) . www-data@fallback.jenkins-ci.org:/var/www/fallback.jenkins-ci.org/
