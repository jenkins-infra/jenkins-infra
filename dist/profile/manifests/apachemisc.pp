#
# Misc. apache settings
#
class profile::apachemisc (
  Boolean $ssh_enabled = false,
) {
  include stdlib # Required to allow using stlib methods and custom datatypes
  include apache
  # log rotation setting lives in another module
  include apachelogcompressor

  # enable mod_status for local interface and allow datadog to monitor this
  include apache::mod::status
  include datadog_agent::integrations::apache

  include apache::mod::proxy
  include apache::mod::proxy_http
  include apache::mod::ssl

  # This should be removed/refactored once this pull request has been merged
  # and released: https://github.com/puppetlabs/puppetlabs-apache/pull/1867
  apache::mod {
    'http2' :
  }

  apache::custom_config { 'http2.conf':
    ensure  => present,
    content => 'Protocols h2 h2c http/1.1',
    require => Apache::Mod['http2'],
  }

  file { '/etc/apache2/conf.d/00-reverseproxy_combined':
    ensure  => file,
    source  => "puppet:///modules/${module_name}/apache/00-reverseproxy_combined.conf",
    mode    => '0444',
    require => Package['apache2-utils'],
    notify  => Service['apache2'],
  }

  file { '/etc/apache2/conf.d/other-vhosts-access-log':
    ensure  => file,
    source  => "puppet:///modules/${module_name}/apache/other-vhosts-access-log.conf",
    mode    => '0444',
    require => Package['apache2-utils'],
    notify  => Service['apache2'],
  }

  # /usr/bin/rotatelogs is (as of 14.04) located in apache2-utils
  package { 'apache2-utils' :
    ensure => present,
  }

  # allow Jenkins to login as www-data to populate some web content
  if $ssh_enabled {
    ssh_authorized_key { 'hudson@cucumber':
      ensure => present,
      user   => 'www-data',
      type   => 'ssh-rsa',
      key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA1l3oZpCJlFspsf6cfa7hovv6NqMB5eAn/+z4SSiaKt9Nsm22dg9xw3Et5MczH0JxHDw4Sdcre7JItecltq0sLbxK6wMEhrp67y0lMujAbcMu7qnp5ZLv9lKSxncOow42jBlzfdYoNSthoKhBtVZ/N30Q8upQQsEXNr+a5fFdj3oLGr8LSj9aRxh0o+nLLL3LPJdY/NeeOYJopj9qNxyP/8VdF2Uh9GaOglWBx1sX3wmJDmJFYvrApE4omxmIHI2nQ0gxKqMVf6M10ImgW7Rr4GJj7i1WIKFpHiRZ6B8C/Ds1PJ2otNLnQGjlp//bCflAmC3Vs7InWcB3CTYLiGnjrw==',
    }
  }

  firewall {
    '200 allow http':
      proto  => 'tcp',
      dport  => 80,
      action => 'accept',
  }

  firewall {
    '201 allow https':
      proto  => 'tcp',
      dport  => 443,
      action => 'accept',
  }
}
