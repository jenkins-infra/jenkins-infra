#
# Role for a Jenkins build agent
class role::jenkins::agent {
  include profile::base

  if $::kernel == 'Darwin' {
    class { 'profile::buildagent':
      docker => false,
      ruby   => false,
    }
  }
  else {
    include profile::buildagent
  }
}
