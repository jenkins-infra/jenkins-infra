#
# Defines an "updates.jenkins.io" server for serving updatesite, aims to deal with volume management
#
class profile::updates() {
  include stdlib
  # volume configuration is in hiera
  include lvm

  package { 'lvm2':
    ensure => present,
  }
}
