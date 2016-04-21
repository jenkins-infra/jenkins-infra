#!/bin/sh -xe

exec bundle exec parallel_rspec spec/classes
