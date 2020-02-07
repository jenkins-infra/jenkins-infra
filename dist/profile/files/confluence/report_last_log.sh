#!/bin/bash
set -euxo pipefail
# make sure all can read this file
umask 100

FINAL_FILE=${FINALFILE:-/var/www/html/reports/top_urls.txt}

# create a temporary file
TMPLOGFILE=`mktemp -p /tmp`
trap "{ rm -f $TMPLOGFILE; }" EXIT

# grab all log files but sort by date
LOGFILENAME=$(find /var/log/apache2/wiki.jenkins-ci.org -name 'access.log*' -not -name 'access.log' -type f | sort -nk1 | \
  # grab the two newest
  tail -n 2 | \
  # then grab the second newest (so one day ago)
  head -n 1)

echo "# LogFile: $(basename $LOGFILENAME)" >> $TMPLOGFILE
echo "# LastUpdated: $(TZ=UTC date)" >> $TMPLOGFILE


# cat it (zcat -f will handled gzip and non gzip files)
zcat -f $LOGFILENAME | \
  # url field
  awk -F" " '$9 == "200" { print $7 }' | \
  # remove the blank lines
  awk 'NF > 0' | \
  # truncate querystring
  awk -F"?" '{print $1}' | \
  # only handle wiki urls
  grep "/display/" | \
  # sort them all
  sort | \
  # sort and count unique
  uniq -c | \
  # sort by the higest number of them
  sort -nrk1 | \
  # find the 100 newest
  head -n 100 >> $TMPLOGFILE
  
if [ "$FINALFILE" = "-" ]; then
  cat $TMPLOGFILE
else
  mv $TMPLOGFILE $FINALFILE
fi

