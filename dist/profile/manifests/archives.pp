#
# Defines an archive server for serving all the archived historical releases
#
class profile::archives (
  # all injected from hiera
  $device,
  $size
) {

  package { 'lvm2':
    ensure => present,
  }

  if str2bool("$vagrant") {
    # during serverspec test, fake /dev/xvdb by a loopback device
    exec { 'create /tmp/xvdb':
      command => 'dd if=/dev/zero of=/tmp/xvdb bs=1M count=16; losetup /dev/loop0; losetup /dev/loop0 /tmp/xvdb',
      unless  => 'test -f /tmp/xvdb',
      path    => '/usr/bin:/usr/sbin:/bin:/sbin',
      before  => Physical_volume[$device],
    }
  }

  # volume configuration is in hiera
  include ::lvm

  file { '/srv/releases':
    ensure  => directory,
    owner   => 'www-data',
    require => [Package['apache2'],Mount['/srv/releases']],
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

    # to prevent crawling, do not serve index. Steer people to mirrors.jenkins-ci.org as the starting point
    options         => ['FollowSymLinks','MultiViews'],

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
