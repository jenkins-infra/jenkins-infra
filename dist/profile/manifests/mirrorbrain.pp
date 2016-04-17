#
# Configure the mirrorbrain service
class profile::mirrorbrain(
  $pg_host      = 'localhost',
  $pg_database  = 'mirrorbrain',
  $pg_username  = 'mirrorbrain',
  $pg_password  = 'mirrorbrain',
  $manage_pgsql = false, # Install and manager PostgreSQL for development
) {
  include ::mirrorbrain
  include ::mirrorbrain::apache

  include profile::apachemisc
  include profile::firewall
  include profile::letsencrypt


  # dbd-pgsql is required to allow mod_dbd to communicate with PostgreSQL
  package { 'libaprutil1-dbd-pgsql':
    ensure  => present,
    require => Class['apache'],
  }
}
