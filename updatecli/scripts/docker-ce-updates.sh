#!/bin/bash
# This script uses apt to find the latest version of docker-ce available.
set -eu -o pipefail

# Upadting the list of latest updates available for installed packages on the system
apt-get update >/dev/null

# Retrieve from apt-cache the latest version of docker-ce available
# Note: apt-cache policy will return a result like:
# :# apt-cache policy docker-ce
# docker-ce:
#   Installed: (none)
#   Candidate: (none)
#   Version table:
# We want to get the Candidate version (which is the latest available)
# And we want it in a readable format
# --
# DEV MEMO: Line explanation:
# 1. Retrieve information about docker-ce from apt
# 2. Keep only the line about the Candidate version (latest available)
# 3. Cut it so we only keep the version and remove title (version contains a :, hence keeping fields 2 and 3)
# 4. Trimming the result (removing spaces before and after)
# 5. Surrounding the result with simple quotes ('') as it'll be needed this way
apt-cache policy docker-ce | grep 'Candidate' | cut -f2,3 -d':' | xargs | { read -r x ; echo "'${x}'"; }
