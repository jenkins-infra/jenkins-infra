#
# Basic profile included in each node
class profile::base {
  include profile::accounts
  include profile::apt
  include profile::ntp
  include profile::sudo

  # Cleaning up after infra-puppet
  cron { 'pull puppet updates':
    ensure => absent,
  }

  cron { 'clean up old puppet logs':
    ensure => absent,
  }

  cron { 'clean the repo-update cache':
    ensure => absent,
  }

  # Clean up the infra-puppet checkout from the disk
  file { '/root/infra-puppet':
    ensure  => absent,
    recurse => true,
    force   => true,
  }
}
