#!/bin/sh -xe

# Show version to help debugging (or fail fast)
yq --version
ruby -v
bundle -v

# Install Unit Test Dependencies
mkdir -p vendor/gems
bundle install --without development plugins --path=vendor/gems

# Resolve Test Fixtures and Puppet modules
bundle exec rake resolve
