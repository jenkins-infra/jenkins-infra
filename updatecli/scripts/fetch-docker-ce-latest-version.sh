#!/bin/bash
# This script uses apt to find the latest version of docker-ce available.
set -eu -o pipefail

for cli in apt-get apt-cache grep cut xargs
do
  if ! command -v $cli >/dev/null 2>&1
  then
    echo "ERROR: command line ${cli} required but not found. Exiting."
    exit 1
  fi
done

# Updating the list of latest updates available for installed packages on the system
apt-get update -q >/dev/null 2>&1
# Installing docker-ce requirements
apt-get install -qy ca-certificates curl gnupg lsb-release apt-utils >/dev/null 2>&1
# Installing docker-ce gpg key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg >/dev/null 2>&1
# Installing docker-ce apt repository
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null 2>&1
# Updating the apt index again
apt-get update -q >/dev/null 2>&1

# Retrieve from apt-cache the latest version of docker-ce available
# Note: apt-cache policy will return a result like:
# :# apt-cache policy docker-ce
# docker-ce:
#   Installed: (none)
#   Candidate: (none)
#   Version table:
# We want to get the Candidate version (which is the latest available)
# And we want it in a readable format
apt-cache policy docker-ce `# 1. Retrieve information about docker-ce from apt` \
  | grep 'Candidate' `# 2. Keep only the line about the Candidate version (latest available)` \
  | cut -f2,3 -d':' `# 3. Cut it so we only keep the version and remove title (version contains a :, hence keeping fields 2 and 3)` \
  | xargs `# 4. Trimming the result (removing spaces before and after)` \
  | { read -r x ; if [ "$x" == '(none)' ]; then exit 1; else echo "'${x}'"; fi }  # 5. Failing if the result is empty or surrounding it with simple quotes ('')
