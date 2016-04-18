#
# Profile for configuring the bare necessities to running a Jenkins master
class profile::buildmaster {
  include profile::firewall

  class { '::jenkins':
    lts       => true,
    executors => 0,
  }
}
