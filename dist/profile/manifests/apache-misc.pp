#
# Misc. apache settings
#
class profile::apache-misc(
  $ssh_enabled = false,
) {
  include apache
  # log rotation setting lives in another module
  include apache-logcompressor

  # enable mod_status for local interface and allow datadog to monitor this
  include apache::mod::status
  include datadog_agent::integrations::apache

  file { '/etc/apache2/conf.d/00-reverseproxy_combined':
    ensure => present,
    source => "puppet:///modules/${module_name}/apache/00-reverseproxy_combined.conf",
    mode   => '0444',
  }

  file { '/etc/apache2/conf.d/other-vhosts-access-log':
    ensure => present,
    source => "puppet:///modules/${module_name}/apache/other-vhosts-access-log.conf",
    mode   => '0444',
  }

  # allow Jenkins to login as www-data to populate some web content
  if $ssh_enabled {
    file { '/var/www/.ssh':
      ensure => directory,
    }

    file { '/var/www/.ssh/authorized_keys':
      ensure  => present,
      content => 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA1l3oZpCJlFspsf6cfa7hovv6NqMB5eAn/+z4SSiaKt9Nsm22dg9xw3Et5MczH0JxHDw4Sdcre7JItecltq0sLbxK6wMEhrp67y0lMujAbcMu7qnp5ZLv9lKSxncOow42jBlzfdYoNSthoKhBtVZ/N30Q8upQQsEXNr+a5fFdj3oLGr8LSj9aRxh0o+nLLL3LPJdY/NeeOYJopj9qNxyP/8VdF2Uh9GaOglWBx1sX3wmJDmJFYvrApE4omxmIHI2nQ0gxKqMVf6M10ImgW7Rr4GJj7i1WIKFpHiRZ6B8C/Ds1PJ2otNLnQGjlp//bCflAmC3Vs7InWcB3CTYLiGnjrw== hudson@cucumber',
    }
  }

  firewall { '200 allow http requests':
    proto  => 'tcp',
    port   => 80,
    action => 'accept',
  }

  firewall { '201 allow https requests':
    proto  => 'tcp',
    port   => 443,
    action => 'accept',
  }

  # Prepare maintenance screen

}
