#!/bin/bash
GIST_ID=
# grab all log files but sort by date
find /var/log/apache2/wiki.jenkins-ci.org -name 'access.log*' -type f -printf "%T+\t%p\n" | sort | \
  # grab the two newest
  tail -n 2 | \
  # then grab the second newest (so one day ago)
  head -n 1 | \
  # cat it
  xargs cat | \
  # url field
  awk -F" " '{print $7}' | \
  # truncate querystring
  awk -F"?" '{print $1}' | \
  # sort them all
  sort | \
  # sort and count unique
  uniq -c | \
  # sort by the higest number of them
  sort -nrk1 | \
  # find the 100 newest
  head -n 100 | \
  # post to git
  gist -u $GIST_ID -f urls.txt

