#!/bin/sh

eval `cat /srv/releases/.azure-storage-env`
wget -O release-blob-sync https://raw.githubusercontent.com/jenkins-infra/azure/master/scripts/release-blob-sync
/usr/bin/ruby release-blob-sync | sh
