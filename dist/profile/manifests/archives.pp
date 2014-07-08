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
  }

  mount { '/srv/releases':
    ensure   => mounted,
    device   => '/dev/archives/releases',
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
    docroot         => '/srv/releases',
    access_log      => false,
    error_log_file  => 'archives.jenkins-ci.org/error.log',
    log_level       => 'warn',
    custom_fragment => template("${module_name}/archives/vhost.conf"),
    notify          => Service['apache2'],
    require         => [File['/var/log/apache2/archives.jenkins-ci.org'],Mount['/srv/releases'],Apache_mod['bw']],
  }
}
