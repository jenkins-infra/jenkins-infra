#
# Profile for managing rngd packet installation
class profile::rngd {

  ['rng-tools'].each | $package | {
    package { $package:
      ensure => present,
    }
  }
}
