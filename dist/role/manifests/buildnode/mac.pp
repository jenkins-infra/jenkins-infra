#
# Provision a simple, SSH-able Mac OS X based Jenkins build node
class role::buildnode::mac {
  include profile::base

  class { 'profile::buildslave':
    docker => false,
    ruby   => false,
  }
}
