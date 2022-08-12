#!/bin/bash

set -eux -o pipefail

echo "> Checking tools version to help debugging (or fail fast)..."
yq --version
ruby -v
bundle -v

echo "> Installing Rubygem Dependencies..."
bundle install

echo "> Resolving Test Fixtures and Puppet modules..."
bundle exec rake resolve
