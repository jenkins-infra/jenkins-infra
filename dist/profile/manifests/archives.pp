#
# Defines an archive server for serving all the archived historical releases
#
class profile::archives {
  include stdlib
  # volume configuration is in hiera
  include ::lvm
  include profile::apache-misc

  $archives_dir = '/srv/releases'

  if str2bool($::vagrant) {
    # during serverspec test, fake /dev/xvdb by a loopback device
    exec { 'create /tmp/xvdb':
      command => 'dd if=/dev/zero of=/tmp/xvdb bs=1M count=16; losetup /dev/loop0; losetup /dev/loop0 /tmp/xvdb',
      unless  => 'test -f /tmp/xvdb',
      path    => '/usr/bin:/usr/sbin:/bin:/sbin',
      before  => Physical_volume['/dev/loop0'],
    }
  }


  package { 'lvm2':
    ensure => present,
  }

  package { 'libapache2-mod-bw':
    ensure => present,
  }


  file { $archives_dir:
    ensure  => directory,
    owner   => 'www-data',
    require => [Package['apache2'],
                Mount[$archives_dir]],
  }


  file { '/var/log/apache2/archives.jenkins-ci.org':
    ensure => directory,
  }

  apache::mod { 'bw':
    require => Package['libapache2-mod-bw'],
  }

  apache::vhost { 'archives.jenkins-ci.org':
    servername      => 'archives.jenkins-ci.org',
    vhost_name      => '*',
    port            => '80',
    docroot         => $archives_dir,
    access_log      => false,
    error_log_file  => 'archives.jenkins-ci.org/error.log',
    log_level       => 'warn',
    custom_fragment => template("${module_name}/archives/vhost.conf"),

    # to prevent crawling, do not serve index. Steer people to mirrors.jenkins-ci.org as the starting point
    options         => ['FollowSymLinks','MultiViews'],

    notify          => Service['apache2'],
    require         => [File['/var/log/apache2/archives.jenkins-ci.org'],
                        Mount[$archives_dir],
                        Apache::Mod['bw']],
  }
}
