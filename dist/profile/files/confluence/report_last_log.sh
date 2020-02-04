#!/bin/bash
# make sure all can read this file
umask 100
# grab all log files but sort by date
find /var/log/apache2/wiki.jenkins-ci.org -name 'access.log*' -type f -printf "%T+\t%p\n" | sort -nk1 | \
  # grab the two newest
  tail -n 2 | \
  # then grab the second newest (so one day ago)
  head -n 1 | \
  # grab the actual filename
  awk -F"\t" '{print $2}' | \
  # cat it (zcat -f will handled gzip and non gzip files)
  xargs zcat -f | \
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
  head -n 100 > /var/www/html/reports/top_urls.txt

