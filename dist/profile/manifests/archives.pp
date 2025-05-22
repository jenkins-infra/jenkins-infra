#
# Defines an archive server for serving all the archived historical releases
#
class profile::archives (
  Array                $rsync_hosts_allow           = [],
  Stdlib::Absolutepath $archives_dir                = '/srv/releases',
  Stdlib::Absolutepath $rsync_motd_file             = '/etc/jenkins.motd',
  Stdlib::Host         $source_mirror_endpoint      = 'ftp-osl.osuosl.org',
  Stdlib::Absolutepath $source_mirror_directory     = '/jenkins/',
  Array                $ssh_authorized_keys         = [],
) {
  include stdlib # Required to allow using stlib methods and custom datatypes
  include profile::apachemisc
  include profile::letsencrypt

  $apache_owner     = 'www-data'
  $apache_group     = $apache_owner

  $archives_fqdn = 'archives.jenkins.io'
  $archives_legacy_fqdn = 'archives.jenkins-ci.org'

  $apache_log_dir_fqdn = "/var/log/apache2/${archives_fqdn}"
  $apache_log_dir_legacy_fqdn = "/var/log/apache2/${archives_legacy_fqdn}"

  ## Manage mirrorsync user and its home directory
  #
  user { 'mirrorsync':
    ensure     => present,
    shell      => '/bin/bash',
    managehome => true,
  }

  # Assume that an existing virtual resource named `User { 'www-data'`
  # already exist
  User <| title == $apache_owner |> {
    groups +> 'mirrorsync'
  }

  # The user mirrorsync is only used to trigger a synchronization
  # between a remote a mirror and the directory as the user www-data
  sudo::conf { 'mirrorsync':
    ensure  => present,
    content => 'mirrorsync ALL=(ALL) NOPASSWD: /usr/bin/mirrorsync',
    require => User['mirrorsync'],
  }

  file { '/home/mirrorsync/.ssh':
    ensure  => 'directory',
    mode    => '0700',
    owner   => 'mirrorsync',
    group   => 'mirrorsync',
    require => User['mirrorsync'],
  }

  if $ssh_authorized_keys.size > 0 {
    $ssh_authorized_keys.each | Hash $ssh_authorized_key | {
      unless 'id' in $ssh_authorized_key {
        notice('"id" is required for the authorized key')
      }

      unless 'type' in $ssh_authorized_key {
        notice('"type" is required for the authorized key')
      }

      unless 'user' in $ssh_authorized_key {
        notice('"user" is required for the authorized key')
      }

      unless 'key' in $ssh_authorized_key {
        notice('"key" is required for the authorized key')
      }

      ssh_authorized_key { $ssh_authorized_key["id"] :
        type    => $ssh_authorized_key["type"],
        user    => $ssh_authorized_key["user"],
        key     => $ssh_authorized_key["key"],
        require => File['/home/mirrorsync/.ssh'],
      }
    }
  }

  package { 'libapache2-mod-bw':
    ensure => present,
  }

  # Create apache dirs
  [$archives_dir, $apache_log_dir_fqdn,$apache_log_dir_legacy_fqdn].each |String $dir| {
    file { $dir:
      ensure  => directory,
      owner   => $apache_owner,
      group   => $apache_group,
      mode    => '0775',
      require => Package['httpd'],
    }
  }

  apache::mod { 'bw':
    require => Package['libapache2-mod-bw'],
  }

  apache::vhost { "${archives_legacy_fqdn} unsecure":
    servername                   => $archives_legacy_fqdn,
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    vhost_name                   => '*',
    port                         => 80,
    docroot                      => $archives_dir,

    access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir_legacy_fqdn}/access_unsecured.log.%Y%m%d%H%M%S 604800",
    error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir_legacy_fqdn}/error_unsecured.log.%Y%m%d%H%M%S 604800",

    redirect_status              => 'permanent',
    redirect_dest                => "https://${archives_legacy_fqdn}/",

    options                      => ['FollowSymLinks', 'MultiViews', 'Indexes'],
    notify                       => Service['apache2'],
    require                      => [
      File[$apache_log_dir_legacy_fqdn],
      File[$archives_dir],
      Apache::Mod['bw']
    ],
  }

  apache::vhost { $archives_legacy_fqdn:
    servername                   => $archives_legacy_fqdn,
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    port                         => 443,
    ssl                          => true,
    docroot                      => $archives_dir,

    access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir_legacy_fqdn}/access.log.%Y%m%d%H%M%S 604800",
    error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir_legacy_fqdn}/error.log.%Y%m%d%H%M%S 604800",

    notify                       => Service['apache2'],
    require                      => [
      File[$apache_log_dir_legacy_fqdn],
      File[$archives_dir],
      Apache::Mod['bw']
    ],
  }

  apache::vhost { "${archives_fqdn} unsecured":
    # redirect non-SSL to SSL
    servername                   => $archives_fqdn,
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    port                         => 80,
    docroot                      => $archives_dir,

    access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir_fqdn}/access_unsecured.log.%Y%m%d%H%M%S 604800",
    error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir_fqdn}/error_unsecured.log.%Y%m%d%H%M%S 604800",

    redirect_status              => 'permanent',
    redirect_dest                => "https://${archives_fqdn}/",
    require                      => [
      File[$apache_log_dir_fqdn],
      File[$archives_dir],
      Apache::Mod['bw']
    ],
  }

  apache::vhost { $archives_fqdn:
    servername                   => $archives_fqdn,
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    port                         => 443,
    ssl                          => true,
    docroot                      => $archives_dir,

    access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir_fqdn}/access.log.%Y%m%d%H%M%S 604800",
    error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir_fqdn}/error.log.%Y%m%d%H%M%S 604800",

    notify                       => Service['apache2'],
    require                      => [
      File[$apache_log_dir_fqdn],
      File[$archives_dir],
      Apache::Mod['bw']
    ],
  }

  # We can only acquire certs in production due to the way the letsencrypt
  # challenge process works
  if (($environment == 'production') and ($facts['vagrant'] != '1')) {
    [$archives_fqdn, $archives_legacy_fqdn].each |String $domain| {
      letsencrypt::certonly { $domain:
        domains => [$domain],
        plugin  => 'apache',
      }

      Apache::Vhost <| title == $domain |> {
        ssl_key         => "/etc/letsencrypt/live/${domain}/privkey.pem",
        ssl_cert        => "/etc/letsencrypt/live/${domain}/fullchain.pem",
      }
    }
  }

  # Install Rsync
  #
  # Rsync is needed by mirrorbits to access file metadata
  # It's a requirement to use archives.jenkins.io as
  # a fallback mirror from get.jenkins.io
  #
  package { 'rsync':
    ensure => present,
  }

  file { '/etc/rsyncd.conf':
    ensure  => file,
    content => template("${module_name}/archives/rsyncd.conf.erb"),
    owner   => 'root',
    mode    => '0600',
    require => Package['rsync'],
  }

  file { $rsync_motd_file:
    ensure  => file,
    source  => "puppet:///modules/${module_name}/archives/jenkins.motd",
    owner   => 'root',
    mode    => '0644',
    require => Package['rsync'],
  }

  service { 'rsync':
    ensure => running,
    enable => true,
  }

  firewall { '100 all inbound rsync':
    proto  => 'tcp',
    dport  => '873',
    action => 'accept',
  }

  # Install a script to trigger mirror synchronization
  #
  file { '/var/log/mirrorsync':
    ensure  => 'directory',
    group   => 'mirrorsync',
    owner   => 'mirrorsync',
    mode    => '0770',
    require => File['/usr/bin/mirrorsync'],
  }

  file { '/usr/bin/mirrorsync':
    content => template("${module_name}/archives/mirrorsync.erb"),
    group   => 'root',
    owner   => 'root',
    mode    => '0755',
  }

  package { 'cron':
    ensure => installed,
  }

  cron { 'mirrorsync':
    command => '/usr/bin/mirrorsync',
    user    => 'mirrorsync',
    minute  => 30,
    require => [File['/usr/bin/mirrorsync'],Package['cron']],
  }
}
