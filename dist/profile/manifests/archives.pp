#
# Defines an archive server for serving all the archived historical releases
#
class profile::archives (
  Array                $rsync_hosts_allow           = ['localhost'],
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

  #
  package { 'lvm2':
    ensure => present,
  }

  package { 'libapache2-mod-bw':
    ensure => present,
  }

  file { $archives_dir:
    ensure  => directory,
    owner   => $apache_owner,
    group   => $apache_group,
    mode    => '0775',
    require => Package['httpd'],
  }

  file { '/var/log/apache2/archives.jenkins-ci.org':
    ensure => directory,
    owner  => $apache_owner,
    group  => $apache_group,
  }

  file { '/var/log/apache2/archives.jenkins.io':
    ensure => directory,
    owner  => $apache_owner,
    group  => $apache_group,
  }

  apache::mod { 'bw':
    require => Package['libapache2-mod-bw'],
  }

  apache::vhost { 'archives.jenkins-ci.org unsecure':
    servername                   => 'archives.jenkins-ci.org',
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    vhost_name                   => '*',
    port                         => '80',
    docroot                      => $archives_dir,
    access_log                   => false,
    error_log_file               => 'archives.jenkins-ci.org/error.log',
    log_level                    => 'warn',
    custom_fragment              => template("${module_name}/archives/vhost.conf"),
    options                      => ['FollowSymLinks', 'MultiViews', 'Indexes'],
    notify                       => Service['apache2'],
    require                      => [File['/var/log/apache2/archives.jenkins-ci.org'],
      File[$archives_dir],
    Apache::Mod['bw']],
  }

  apache::vhost { 'archives.jenkins-ci.org':
    servername                   => 'archives.jenkins-ci.org',
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    port                         => '443',
    ssl                          => true,
    docroot                      => $archives_dir,
    access_log                   => false,
    error_log_file               => 'archives.jenkins-ci.org/error.log',
    log_level                    => 'warn',
    custom_fragment              => template("${module_name}/archives/vhost.conf"),

    notify                       => Service['apache2'],
    require                      => File['/var/log/apache2/archives.jenkins-ci.org'],
  }

  apache::vhost { 'archives.jenkins.io unsecured':
    # redirect non-SSL to SSL
    servername                   => 'archives.jenkins.io',
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    port                         => '80',
    docroot                      => $archives_dir,
    redirect_status              => 'temp',
    redirect_dest                => 'https://archives.jenkins.io/',
  }

  apache::vhost { 'archives.jenkins.io':
    servername                   => 'archives.jenkins.io',
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    port                         => '443',
    ssl                          => true,
    docroot                      => $archives_dir,
    access_log                   => false,
    error_log_file               => 'archives.jenkins.io/error.log',
    log_level                    => 'warn',
    custom_fragment              => template("${module_name}/archives/vhost.conf"),

    notify                       => Service['apache2'],
    require                      => File['/var/log/apache2/archives.jenkins-ci.org'],
  }

  # We can only acquire certs in production due to the way the letsencrypt
  # challenge process works
  if (($environment == 'production') and ($facts['vagrant'] != '1')) {
    letsencrypt::certonly { 'archives.jenkins.io':
      domains => ['archives.jenkins.io','archives.jenkins-ci.org'],
      plugin  => 'apache',
    }
    Apache::Vhost <| title == 'archives.jenkins.io' |> {
      # When Apache is upgraded to >= 2.4.8 this should be changed to
      # fullchain.pem
      ssl_key       => '/etc/letsencrypt/live/archives.jenkins.io/privkey.pem',
      ssl_cert      => '/etc/letsencrypt/live/archives.jenkins.io/fullchain.pem',
      ssl_chain     => '/etc/letsencrypt/live/archives.jenkins.io/chain.pem',
    }
    Apache::Vhost <| title == 'archives.jenkins-ci.org' |> {
      ssl_key       => '/etc/letsencrypt/live/archives.jenkins.io/privkey.pem',
      ssl_cert      => '/etc/letsencrypt/live/archives.jenkins.io/fullchain.pem',
      ssl_chain     => '/etc/letsencrypt/live/archives.jenkins.io/chain.pem',
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

  cron { 'mirrorsync':
    command => '/usr/bin/mirrorsync',
    user    => 'mirrorsync',
    minute  => 30,
    require => File['/usr/bin/mirrorsync'],
  }
}
