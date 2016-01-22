# Instance for running our tests quickly and easily
FROM ubuntu:trusty
MAINTAINER tyler@linux.com

# Packages we need for a sane build
#  * ruby, ruby-dev, zlib1g-dev: all to ensure `bundle install` works properly
#  * git: duh
#  * build-essential: make sure Ruby has some tools for building native
#    extensions
#  * bind9utils: ensure we can verify DNS zones
RUN apt-get update -q && apt-get install -qy git build-essential zlib1g-dev ruby ruby-dev bind9utils && apt-get clean
RUN gem install bundler --no-ri --no-rdoc
