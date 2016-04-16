#
# Profile for configuring the bare necessities to running a Jenkins master
class profile::buildmaster {
  class { '::jenkins':
    lts       => true,
    executors => 0,
  }
}
