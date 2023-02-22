# Profile for managing rngd packet installation
class profile::rngd {
  # This package exists on ubuntu 18.04, 20.04 and 22.04
  package { 'rng-tools5':
    ensure => present,
  }

  # This package is the "legacy" on ubuntu 18.04 and 20.04, but is renamed as 'rng-tools-debian' on 22.04+
  package { 'rng-tools':
    ensure => absent,
  }
}
