#
# Configure the mirrorbrain service
class profile::mirrorbrain (
  $pg_host      = 'localhost',
  $pg_database  = 'mirrorbrain',
  $pg_username  = 'mirrorbrain',
  $pg_password  = 'mirrorbrain',
  $manage_pgsql = false, # Install and manager PostgreSQL for development
  $docroot      = '/srv/releases/jenkins',
) {
  include ::mirrorbrain
  include ::mirrorbrain::apache

  include profile::apachemisc
  include profile::firewall
  include profile::letsencrypt

  $server_name = 'mirrors.jenkins.io'
  $apache_log_dir = "/var/log/apache2/${server_name}"
  $mb_user = 'mirrorbrain'
  $mb_group = 'mirrorbrain'


  # We use the mirrorbrain user for interactive things like rsyncing for
  # completing releases and updating the updates site
  user { $mb_user:
    ensure => present,
    shell  => '/bin/bash',
  }

  file { '/etc/mirrorbrain.conf':
    ensure  => present,
    owner   => $mb_user,
    group   => $mb_group,
    content => template("${module_name}/mirrorbrain/mirrorbrain.conf.erb"),
  }

  file { '/etc/mirmon.conf':
    ensure  => present,
    owner   => $mb_user,
    group   => $mb_group,
    content => template("${module_name}/mirrorbrain/mirmon.conf.erb"),
  }

  # Updating our TIME file allows us to easily tell how far mirrors have drived
  file { '/usr/local/bin/mirmon-time-update':
    ensure  => present,
    owner   => 'root',
    mode    => '0755',
    content => "
#!/bin/sh

perl -e 'printf \"%s\n\", time' > ${docroot}/TIME'
",
    require => File[$docroot],
  }

  ## Cron tasks
  #############
  cron { 'mirrorbrain-time-update':
    command => '/usr/local/bin/mirmon-time-update',
    user    => 'root',
    minute  => 2,
    require => File['/usr/local/bin/mirmon-time-update'],
  }

  cron { 'mirmon-status-page':
    command => '/usr/bin/mirmon -q -get update -c /etc/mirmon.conf',
    user    => 'root',
    minute  => '*/15',
    require => File['/etc/mirmon.conf'],
  }

  cron { 'mirrorbrain-ping-mirrors':
    command => '/usr/bin/mirrorprobe',
    user    => 'root',
    minute  => '*/30',
    require => File['/etc/mirrorbrain.conf'],
  }

  # Scan our mirrors, will run as many concurrent jobs as their are processors
  # on the machine
  cron { 'mirrorbrain-scan':
    command => "/usr/bin/mb scan --quiet --jobs ${::processorcount} --all",
    user    => 'root',
    minute  => '*/30',
    require => File['/etc/mirrorbrain.conf'],
  }

  # perform regular clean up of our postgresql database
  cron { 'mirrorbrain-db-cleanup':
    command => '/usr/bin/mb db vacuum',
    user    => 'root',
    hour    => 2,
    minute  => 42,
    require => File['/etc/mirrorbrain.conf'],
  }

  cron { 'mirmon-update-mirror-list':
    command => '/usr/bin/mb export --format=mirmon > /srv/releases/mirror_list',
    user    => 'root',
    minute  => '*/10',
    require => File['/etc/mirrorbrain.conf'],
  }
  #############

  # dbd-pgsql is required to allow mod_dbd to communicate with PostgreSQL
  package { 'libaprutil1-dbd-pgsql':
    ensure  => present,
    require => Class['apache'],
  }

  $dbd_conf = '/etc/apache2/mods-available/dbd.conf'
  $geoip_conf = '/etc/apache2/mods-available/geoip.conf'

  file { $dbd_conf:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    content => template("${module_name}/mirrorbrain/dbd.conf.erb"),
  }

  file { '/etc/apache2/mods-enabled/dbd.conf':
    ensure  => link,
    target  => $dbd_conf,
    require => [
        File[$dbd_conf],
        Package['libaprutil1-dbd-pgsql'],
    ],
    notify  => Service['apache2'],
  }

  file { $geoip_conf:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    require => Apache::Mod['geoip'],
    source  => "puppet:///modules/${module_name}/mirrorbrain/geoip.conf",
  }

  file { '/etc/apache2/mods-enabled/geoip.conf':
    ensure  => link,
    target  => $geoip_conf,
    require => [
        File[$geoip_conf],
    ],
    notify  => Service['apache2'],
  }

  file { $apache_log_dir:
    ensure => directory,
  }

  # This is dumb.
  exec { 'mirrorbrain-mkdirp':
    command => "/bin/mkdir -p ${docroot}",
    creates => $docroot,
  }

  apache::vhost { $server_name:
    serveraliases     => [
      'mirrors.jenkins-ci.org',
    ],
    port              => 80,
    serveradmin       => 'infra@lists.jenkins-ci.org',
    docroot           => $docroot,
    access_log_format =>  '\"%{X-Forwarded-For}i\" %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" want:%{WANT}e give:%{GIVE}e r:%{MB_REALM}e %{X-MirrorBrain-Mirror}o %{MB_CONTINENT_CODE}e:%{MB_COUNTRY_CODE}e ASN:%{ASN}e P:%{PFX}e size:%{MB_FILESIZE}e %{Range}i forw:%{x-forwarded-for}i',
    access_log_pipe   => "|/usr/bin/rotatelogs ${apache_log_dir}/access.log.%Y%m%d%H%M%S 604800",
    error_log_file    => "${server_name}/error.log",
    require           => [
        File[$apache_log_dir],
        Package['apache2-utils'], # For log rotation
        Exec['mirrorbrain-mkdirp'],
    ],
    override          => ['All'],
    aliases           => [
      {
        alias => '/mirmon/icons',
        path  => '/usr/share/mirmon/icons',
      },
    ],
    directories       => [
      {
        path            => $docroot,
        options         => 'FollowSymLinks Indexes',
        allow_override  => ['All'],
        custom_fragment => '
            MirrorBrainEngine On
            MirrorBrainDebug Off
            FormGET On
            MirrorBrainHandleHEADRequestLocally Off

            # we serve most files from mirrors, but as a fallback,
            # this slow server has everything.
            MirrorBrainFallback na us http://archives.jenkins-ci.org/

            # Do not redirect for files smaller than 4096 bytes
            MirrorBrainMinSize 4096
            ## NOTE: Re-enabling these exclude rules will kill our bandwidth allocation.
            #MirrorBrainExcludeUserAgent rpm/4.4.2*
            #MirrorBrainExcludeUserAgent *APT-HTTP*

            MirrorBrainExcludeMimeType application/pgp-keys
            MirrorBrainExcludeMimeType text/html
        ',
      },
      {
        path           => '/usr/share/mirmon/icons',
        options        => 'None',
        allow_override => ['None'],
      },
    ],
  }
}
