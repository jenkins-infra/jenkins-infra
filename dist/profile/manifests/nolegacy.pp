#
# This profile is a simple profile to ensure the removal of the legacy
# "infra-puppet" code which ran masterless puppet
class profile::nolegacy {
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
