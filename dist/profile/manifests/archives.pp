#
# Defines an archive server for serving all the archived historical releases
#
class profile::archives (
  Array                $rsync_hosts_allow            = [],
  Stdlib::Absolutepath $data_disk_mount              = '/srv',
  Stdlib::Absolutepath $rsync_motd_file              = '/etc/jenkins.motd',
  Array                $ssh_authorized_keys          = [],
  Integer              $bandwidth_per_vhost_in_bytes = 1024000, # Defaults to 10 Mb/s
) {
  include stdlib # Required to allow using stlib methods and custom datatypes
  include profile::apachemisc
  include profile::letsencrypt

  $mirrorsync_user  = 'mirrorsync'
  $mirrorsync_group = $mirrorsync_user

  $apache_owner     = 'www-data'
  $apache_group     = $apache_owner

  $archives_dir = "${data_disk_mount}/releases"

  $archives_fqdn = 'archives.jenkins.io'
  $archives_legacy_fqdn = 'archives.jenkins-ci.org'

  $apache_log_dir_fqdn = "/var/log/apache2/${archives_fqdn}"
  $apache_log_dir_legacy_fqdn = "/var/log/apache2/${archives_legacy_fqdn}"

  $mirror_base_rsync_filter = "${data_disk_mount}/rsync.filter"
  $mirrorsync_user_home = "/home/${mirrorsync_user}"
  # Note: name does not change with username
  $mirrorsync_script_path = '/usr/bin/mirrorsync'
  $osuosl_mirroring = {
    'host'        => lookup('osuosl_mirroring::host'),
    'username'    => lookup('osuosl_mirroring::username'),
    'privkey'     => lookup('osuosl_mirroring::privkey'),
    'keypath'     => "${mirrorsync_user_home}/.ssh/osuosl_mirror",
    'known_hosts' => lookup('osuosl_mirroring::known_hosts'),
  }

  ## Manage mirrorsync user and its home directory
  group { $mirrorsync_group:
    ensure => 'present',
  }
  user { $mirrorsync_user:
    ensure     => present,
    shell      => '/bin/bash',
    managehome => true,
    home       => $mirrorsync_user_home,
    gid        => $mirrorsync_group,
    groups     => [$apache_group],
    require    => [
      Group[$mirrorsync_group],
      Group[$apache_owner],
    ],
  }

  # Assume that an existing virtual resource named `User { 'www-data'`
  # already exist
  User <| title == $apache_owner |> {
    groups +> $mirrorsync_user,
  }

  # The user mirrorsync is only used to trigger a synchronization
  # between a remote a mirror and the directory as the user www-data
  sudo::conf { $mirrorsync_user:
    ensure  => present,
    content => "${$mirrorsync_user} ALL=(ALL) NOPASSWD: ${mirrorsync_script_path}",
    require => User[$mirrorsync_user],
  }

  file { "${mirrorsync_user_home}/.ssh":
    ensure  => 'directory',
    mode    => '0700',
    owner   => $mirrorsync_user,
    group   => $mirrorsync_user, # Same group name as user (expected to ensure privacy)
    require => User[$mirrorsync_user],
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
        require => File["${mirrorsync_user_home}/.ssh"],
      }
    }
  }

  file { $osuosl_mirroring['keypath']:
    ensure  => file,
    owner   => $mirrorsync_user,
    group   => $mirrorsync_group,
    mode    => '0600',
    content => $osuosl_mirroring['privkey'],
    require => [
      User[$mirrorsync_user],
      File["${mirrorsync_user_home}/.ssh"],
    ],
  }

  file { "${mirrorsync_user_home}/.ssh/config":
    ensure  => file,
    owner   => $mirrorsync_user,
    group   => $mirrorsync_group,
    mode    => '0600',
    content => "
Host ${$osuosl_mirroring['host']}
    IdentityFile ${$osuosl_mirroring['keypath']}
",
    require => [
      User[$mirrorsync_user],
      File["${mirrorsync_user_home}/.ssh"],
      File[$osuosl_mirroring['keypath']],
    ],
  }

  file { "${mirrorsync_user_home}/.ssh/known_hosts":
    ensure  => file,
    owner   => $mirrorsync_user,
    group   => $mirrorsync_group,
    mode    => '0600',
    content => $osuosl_mirroring['known_hosts'].join("\n"),
    require => [
      User[$mirrorsync_user],
      File["${mirrorsync_user_home}/.ssh"],
    ],
  }

  # Apache mod-bw may be used to control the download bandwidth/add rate limit
  package { 'libapache2-mod-bw':
    ensure => present,
  }

  # Create dirs owned by mirrorsync user but required by httpd service
  # Note: apache user is expected to be a member of the mirrorbits group
  [$archives_dir].each |String $dir| {
    file { $dir:
      ensure  => directory,
      owner   => $mirrorsync_user,
      group   => $mirrorsync_group,
      mode    => '0755',
      require => [
        User[$mirrorsync_user],
        Group[$mirrorsync_group],
      ],
    }
  }
  # Create dirs owned by apache and required by httpd service
  [$apache_log_dir_fqdn,$apache_log_dir_legacy_fqdn].each |String $dir| {
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

  $mod_bw_config_fragment = "
BandwidthModule On
ForceBandWidthModule On
Bandwidth all \"${bandwidth_per_vhost_in_bytes}\"

"

  apache::vhost { "${archives_legacy_fqdn} unsecure":
    servername                   => $archives_legacy_fqdn,
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    vhost_name                   => '*',
    port                         => 80,
    docroot                      => $archives_dir,
    custom_fragment              => $mod_bw_config_fragment,

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
    custom_fragment              => $mod_bw_config_fragment,

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
    custom_fragment              => $mod_bw_config_fragment,

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
    custom_fragment              => $mod_bw_config_fragment,

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
  file { '/var/log/mirrorsync':
    ensure => 'directory',
    group  => $mirrorsync_user,
    owner  => $mirrorsync_user,
    mode   => '0770',
  }

  file { $mirror_base_rsync_filter:
    content => template("${module_name}/archives/rsync.filter.erb"),
    group   => 'root',
    owner   => 'root',
    mode    => '0644',
  }

  file { $mirrorsync_script_path:
    content => template("${module_name}/archives/mirrorsync.erb"),
    group   => 'root',
    owner   => 'root',
    mode    => '0755',
    require => [
      File['/var/log/mirrorsync'],
      File[$mirror_base_rsync_filter],
    ],
  }

  package { 'cron':
    ensure => installed,
  }

  cron { $mirrorsync_user:
    command => $mirrorsync_script_path,
    user    => $mirrorsync_user,
    minute  => '*/10', # Every 10 minutes
    require => [
      File[$mirrorsync_script_path],
      Package['cron'],
    ],
} }
