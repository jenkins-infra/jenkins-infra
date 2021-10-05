#!/bin/bash

set -eux -o pipefail

operating_system="${1}"
cpu_architecture="${2}"
image_version="${3}"

## As GitHub Actions forbids credentials from forks, we have this special hack to print a dummy string but not failing updatecli diff
# to ensure other configurations are fine.
export DRY_RUN
if ! aws configure list >/dev/null 2>&1 && DRY_RUN="true"
then
  echo "dummy-value-no-aws-credential-and-dryrun-enabled"
  exit 0
fi

##
# - https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-filter.html is a great help to understand filtering, sorting and querying with jmespath and aws CLI
# - Do NOT use multiple times the flag "--filters" (only the last one is used which can leads to unwanted results such as ignoring the other filters)
RESULTING_AMI="$(aws ec2 describe-images \
  --owners 200564066411 `# Owner ID for AWS account cloudbees-jenkins` \
  --region=us-east-2 `#AWS region where ci.jenkins.io runs its EC2 agents` \
  --filters "Name=name,Values=jenkins-agent-${operating_system}-${cpu_architecture}-*" `# Search by name, with a pattern for the end (timestamps)` \
    "Name=tag:build_type,Values=prod" `# Only retrieve production ready AMIs` \
    "Name=tag:version,Values=${image_version}" `# image version is a semantic version v2 string` \
  --query 'sort_by(Images, &CreationDate)[-1].[ImageId]' `# Get the most recent one by sorting by creation date and get the latest and extract its AMI ID` \
  --output text `# We don't want JSON`)"

if [[ "${RESULTING_AMI}" != "ami-"* ]]
then
  >&2 echo "ERROR: the string returned by the AWS command line does not look like an AMI ID: ${RESULTING_AMI}."
  exit 1
fi

echo "${RESULTING_AMI}"
