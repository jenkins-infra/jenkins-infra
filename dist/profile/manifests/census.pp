#
# Defines an census server for serving census datasets
#
class profile::census {
  include ::stdlib
  # volume configuration is in hiera
  include ::lvm
  include profile::apachemisc

  $census_dir = '/srv/census'

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

  file { $census_dir:
    ensure  => directory,
    owner   => 'www-data',
    require => [Package['httpd'],
                Mount[$census_dir]],
  }

  file { '/etc/census':
    ensure => directory,
    owner  => 'www-data',
    mode   => '0750',
  }

  file { '/etc/census/anonymized-passwords':
    ensure => present,
    owner  => 'www-data',
    mode   => '0600',
    source => "puppet:///modules/${module_name}/census/anonymized-passwords",
  }

  file { '/etc/census/monthly-passwords':
    ensure => present,
    owner  => 'www-data',
    mode   => '0600',
    source => "puppet:///modules/${module_name}/census/monthly-passwords",
  }


  file { '/var/log/apache2/census.jenkins.io':
    ensure => directory,
  }

  apache::vhost { 'census.jenkins.io':
    servername      => 'census.jenkins.io',
    vhost_name      => '*',
    port            => '80',
    docroot         => $census_dir,
    access_log      => false,
    error_log_file  => 'census.jenkins.io/error.log',
    log_level       => 'warn',
    custom_fragment => template("${module_name}/census/vhost.conf"),
    options         => ['FollowSymLinks', 'MultiViews', 'Indexes'],
    notify          => Service['apache2'],
    require         => [File['/var/log/apache2/census.jenkins.io'],
                        File['/etc/census/monthly-passwords'],
                        File['/etc/census/anonymized-passwords'],
                        Mount[$census_dir]],
  }
}
