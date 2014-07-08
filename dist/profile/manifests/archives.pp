#
# Defines an archive server for serving all the archived historical releases
#
class profile::archives {
  package { 'lvm2':
    ensure => present,
  }

  # create volume for storage
  physical_volume { '/dev/xvdb':
    ensure  => present,
    require => Package['lvm2'],
  }

  volume_group { 'archives':
    ensure           => present,
    physical_volumes => '/dev/xvdb',
    require      => Physical_volume['/dev/xvdb']
  }

  logical_volume { 'releases':
    ensure       => present,
    volume_group => 'archives',
    size         => '100G',
    require      => Volume_group['archives']
  }

  filesystem { '/dev/archives/releases':
    ensure  => present,
    fs_type => 'ext3',
    require => Logical_volume['releases'],
  }

  file { '/srv':
    ensure  => directory,
  }

  file { '/srv/releases':
    ensure  => directory,
    owner   => 'www-data',
    require => Package['apache2'],
  }

  mount { '/srv/releases':
    ensure   => mounted,
    device   => '/dev/archives/releases',
    fstype   => 'ext3',
    options  => 'defaults',
    require  => [File['/srv/releases'],Filesystem['/dev/archives/releases']],
  }




  file { '/var/log/apache2/archives.jenkins-ci.org':
    ensure => directory,
  }

  include apache

  package { 'libapache2-mod-bw':
    ensure => present,
  }

  apache::mod { 'bw':
    require => Package['libapache2-mod-bw'],
  }

  apache::vhost { 'archives.jenkins-ci.org':
    servername      => 'archives.jenkins-ci.org',
    vhost_name      => '*',
    port            => '80',
    docroot         => '/srv/releases',
    access_log      => false,
    error_log_file  => 'archives.jenkins-ci.org/error.log',
    log_level       => 'warn',
    custom_fragment => template("${module_name}/archives/vhost.conf"),
    notify          => Service['apache2'],
    require         => [File['/var/log/apache2/archives.jenkins-ci.org'],Mount['/srv/releases']],
    # can't figure out how to depend on ,Apache_mod['bw']
  }

  # allow Jenkins to login as www-data to populate the releases
  file { '/var/www/.ssh':
    ensure => directory,
  }
  file { '/var/www/.ssh/authorized_keys':
    ensure  => present,
    content => 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA1l3oZpCJlFspsf6cfa7hovv6NqMB5eAn/+z4SSiaKt9Nsm22dg9xw3Et5MczH0JxHDw4Sdcre7JItecltq0sLbxK6wMEhrp67y0lMujAbcMu7qnp5ZLv9lKSxncOow42jBlzfdYoNSthoKhBtVZ/N30Q8upQQsEXNr+a5fFdj3oLGr8LSj9aRxh0o+nLLL3LPJdY/NeeOYJopj9qNxyP/8VdF2Uh9GaOglWBx1sX3wmJDmJFYvrApE4omxmIHI2nQ0gxKqMVf6M10ImgW7Rr4GJj7i1WIKFpHiRZ6B8C/Ds1PJ2otNLnQGjlp//bCflAmC3Vs7InWcB3CTYLiGnjrw== hudson@cucumber',
  }
}
