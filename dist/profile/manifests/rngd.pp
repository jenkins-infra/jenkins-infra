# Profile for managing rngd packet installation
class profile::rngd {
  package { 'rng-tools5':
    ensure => present,
  }
}
