#!/bin/sh -xe

gem install bundler --no-ri --no-rdoc

mkdir -p vendor/gems

bundle install --verbose --without development plugins --path=vendor/gems

# clean out old fixtures just in case they were left there by a previous build
bundle exec rake spec_clean || true
