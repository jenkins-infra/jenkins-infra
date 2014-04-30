#!/bin/sh -xe

gem install bundler --no-ri --no-rdoc

bundle install --without development plugins
