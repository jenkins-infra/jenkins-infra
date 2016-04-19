#
# Role for a Jenkins build agent
class role::jenkins::agent {
  include profile::base

  if $::kernel == 'Darwin' {
    class { 'profile::buildslave':
      docker => false,
      ruby   => false,
    }
  }
  else {
    include profile::buildslave
  }
}
