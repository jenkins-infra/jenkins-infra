#!/bin/sh

set -eux

MAVEN_VERSION="${1}"

command -v curl >/dev/null 2>&1 || { echo "ERROR: curl command not found. Exiting."; exit 1; }

curl --connect-timeout 5 --location --head --fail --silent --show-error \
  "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
