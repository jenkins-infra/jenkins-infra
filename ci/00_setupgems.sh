#!/bin/sh -xe

gem install bundler --no-ri --no-rdoc

bundle install --without development plugins

# clean out old fixtures just in case they were left there by a previous build
bundle exec rake spec_clean || true
