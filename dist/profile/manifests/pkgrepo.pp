#
# Manage yum and apt repositories for Jenkins
class profile::pkgrepo (
  Stdlib::Absolutepath $docroot         = '/var/www/pkg.jenkins.io',
  Stdlib::Absolutepath $release_root    = '/srv/releases/jenkins',
  Stdlib::Absolutepath $mirror_scripts  = '/srv/releases/mirror-scripts',
  Stdlib::Fqdn $repo_fqdn               = 'pkg.origin.jenkins.io',
  Stdlib::Fqdn $repo_legacy_fqdn        = 'pkg.jenkins-ci.org',
  Stdlib::Fqdn $mirror_fqdn             = 'mirrors.jenkins.io',
  Stdlib::Absolutepath $mirror_home_dir = '/srv/releases',
  String $mirror_git_remote             = 'https://github.com/jenkins-infra/mirror-scripts.git',
  String $mirror_user                   = 'mirrorbrain',
  String $mirror_group                  = 'mirrorbrain',
  String $www_common_group              = 'www-data',
  Hash $ssh_keys                        = {},
) {
  include stdlib # Required to allow using stlib methods and custom datatypes
  include apache
  include apache::mod::rewrite
  include profile::apachemisc
  include profile::firewall
  include profile::letsencrypt

  ################################################################################################
  ###### Tooling / scripts required for pkg and update site (used to be manually managed)
  ###### Some of this code is retrieved from the former profile 'mirrorbrain' to un-tangle pkg and mirrorbrain services - https://github.com/jenkins-infra/jenkins-infra/pull/2185/files
  # Ubuntu 20.04+ are not supported (createrepo package absent).
  case $facts['os']['distro']['codename'] {
    'bionic': {
      # Needed so we can generate repodata on the machine
      ['createrepo','python2.7'].each |$pkg| {
        package { $pkg:
          ensure => present,
        }
      }

      exec { 'Define python2.7 as the default system python':
        require => Package['python2.7'],
        # Last argument is the weight. Bigger weight wins
        command => '/usr/bin/update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1000',
        unless  => '/usr/bin/python --version 2>&1 | grep --quiet "2\.7\."',
      }
    }
    # TODO: add support of Ubuntu 22.04 Jammy with the createrepo-c package instead. Ref. https://github.com/jenkins-infra/release/issues/202.
    default: {
      fail('[profile::pkgrepo] Unsupported Ubuntu distribution (ref. "createrepo" package).')
    }
  }

  package { 'git':
    ensure => 'installed',
  }

  group { $mirror_group:
    ensure => present,
  }

  ## We use the "mirror" user for all the plugin/core/package sync tasks from/to this machine
  account { $mirror_user:
    manage_home    => true,
    # Ensure that our homedir is world-readable, since it's full of public files :)
    home_dir_perms => '0755',
    create_group   => false,
    home_dir       => $mirror_home_dir,
    gid            => $mirror_group,
    # Allow apache user to read some of the files in this directory, through the "read" permission for groups
    groups         => [$www_common_group],
    require        => Group[$mirror_group],
    ssh_keys       => $ssh_keys,
  }

  exec { "Ensure ${mirror_git_remote} is cloned to ${mirror_scripts}":
    require => [Account[$mirror_user],Package['git']],
    user    => $mirror_user,
    command => "/usr/bin/git clone ${mirror_git_remote} ${mirror_scripts}",
    creates => "${mirror_scripts}/.git/config",
  }

  [
    'populate-archives.sh',
    'populate-fallback.sh',
    'sync-recent-releases.sh',
    'sync.sh',
    'update-latest-symlink.sh',
    'rsync.filter',
  ].each | $mirror_file | {
    file { "${mirror_home_dir}/${mirror_file}":
      ensure  => 'link',
      require => [
        Exec["Ensure ${mirror_git_remote} is cloned to ${mirror_scripts}"],
        Account[$mirror_user],
      ],
      target  => "${mirror_scripts}/${mirror_file}",
      owner   => $mirror_user,
      group   => $mirror_group,
    }
  }

  ################################################################################################
  ## Azcopy
  include profile::azcopy
  ################################################################################################

  $apache_log_dir_fqdn = "/var/log/apache2/${repo_fqdn}"
  $apache_log_dir_legacy_fqdn = "/var/log/apache2/${repo_legacy_fqdn}"

  # Create apache dirs
  [$apache_log_dir_fqdn,$apache_log_dir_legacy_fqdn].each |String $dir| {
    file { $dir:
      ensure => directory,
    }
  }

  [$docroot, $release_root].each |String $dir| {
    file { $dir:
      ensure => directory,
      owner  => $mirror_user,
      group  => $www_common_group,
      mode   => '0755',
    }
  }

  $repos = [
    "${docroot}/debian",
    "${docroot}/debian-rc",
    "${docroot}/debian-stable",
    "${docroot}/debian-stable-rc",
    "${docroot}/redhat",
    "${docroot}/redhat-rc",
    "${docroot}/redhat-stable",
    "${docroot}/redhat-stable-rc",
    "${docroot}/opensuse",
    "${docroot}/opensuse-rc",
    "${docroot}/opensuse-stable",
    "${docroot}/opensuse-stable-rc",
  ]

  file { $repos:
    ensure  => directory,
    owner   => $mirror_user,
    group   => $www_common_group,
    mode    => '0755',
    require => File[$docroot],
  }

  file { suffix($repos, '/jenkins-ci.org.key'):
    ensure  => file,
    source  => "puppet:///modules/${module_name}/pkgrepo/jenkins-ci.org.key",
    owner   => $mirror_user,
    group   => $www_common_group,
    mode    => '0644',
    require => File[$docroot],
  }

  file { suffix($repos, '/jenkins.io.key'):
    ensure  => file,
    source  => "puppet:///modules/${module_name}/pkgrepo/jenkins-ci.org.key",
    owner   => $mirror_user,
    group   => $www_common_group,
    mode    => '0644',
    require => File[$docroot],
  }

  file { suffix($repos, '/jenkins-ci.org-2023.key'):
    ensure  => file,
    source  => "puppet:///modules/${module_name}/pkgrepo/jenkins.io-2023.key",
    owner   => $mirror_user,
    group   => $www_common_group,
    mode    => '0644',
    require => File[$docroot],
  }

  file { suffix($repos, '/jenkins.io-2023.key'):
    ensure  => file,
    source  => "puppet:///modules/${module_name}/pkgrepo/jenkins.io-2023.key",
    owner   => $mirror_user,
    group   => $www_common_group,
    mode    => '0644',
    require => File[$docroot],
  }

  profile::redhat_repo { ['redhat', 'redhat-stable', 'redhat-rc', 'redhat-stable-rc']:
    ensure    => present,
    docroot   => $docroot,
    repo_fqdn => $repo_fqdn,
    require   => File[$repos],
  }

  profile::debian_repo { ['debian', 'debian-stable', 'debian-rc', 'debian-stable-rc']:
    ensure      => present,
    docroot     => $docroot,
    direct_root => $release_root,
    mirror_fqdn => $mirror_fqdn,
    require     => File[$repos],
  }

  profile::opensuse_repo { ['opensuse', 'opensuse-stable', 'opensuse-rc', 'opensuse-stable-rc']:
    ensure      => present,
    docroot     => $docroot,
    mirror_fqdn => $mirror_fqdn,
    require     => File[$repos],
  }

  apache::vhost { $repo_fqdn:
    servername                   => $repo_fqdn,
    port                         => 443,
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    # We need FollowSymLinks to ensure our fallback for old APT clients works
    # properly, see debian's htaccess file for more
    options                      => ['Indexes', 'FollowSymLinks', 'MultiViews'],
    override                     => ['All'],
    ssl                          => true,
    docroot                      => $docroot,

    access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir_fqdn}/access.log.%Y%m%d%H%M%S 604800",
    error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir_fqdn}/error.log.%Y%m%d%H%M%S 604800",
    require                      => File[$docroot],
  }

  apache::vhost { "${repo_fqdn} unsecured":
    servername                   => $repo_fqdn,
    port                         => 80,
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    override                     => ['All'],
    docroot                      => $docroot,

    access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir_fqdn}/access_unsecured.log.%Y%m%d%H%M%S 604800",
    error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir_fqdn}/error_unsecured.log.%Y%m%d%H%M%S 604800",
    require                      => File[$docroot],
  }

  apache::vhost { 'pkg.jenkins-ci.org unsecured':
    servername                   => 'pkg.jenkins-ci.org',
    port                         => 80,
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    docroot                      => $docroot,

    access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir_legacy_fqdn}/access_unsecured.log.%Y%m%d%H%M%S 604800",
    error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir_legacy_fqdn}/error_unsecured.log.%Y%m%d%H%M%S 604800",
    redirect_status              => 'permanent',
    redirect_dest                => ['https://pkg.jenkins.io/'],
    # Due to fastly caching on the target domain, it is required to force re-establishing TLS connection to new domain (HTTP/2 tries to reuse connection thinking it is the same server)
    custom_fragment              => 'Protocols http/1.1',
    require                      => File[$docroot],
  }

  apache::vhost { 'pkg.jenkins-ci.org':
    servername                   => 'pkg.jenkins-ci.org',
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    port                         => 443,
    docroot                      => $docroot,
    ssl                          => true,

    access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir_legacy_fqdn}/access.log.%Y%m%d%H%M%S 604800",
    error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir_legacy_fqdn}/error.log.%Y%m%d%H%M%S 604800",
    redirect_status              => 'permanent',
    redirect_dest                => ['https://pkg.jenkins.io/'],
    # Due to fastly caching on the target domain, it is required to force re-establishing TLS connection to new domain (HTTP/2 tries to reuse connection thinking it is the same server)
    custom_fragment              => 'Protocols http/1.1',
    require                      => File[$docroot],
  }

  # We can only acquire certs in production due to the way the letsencrypt
  # challenge process works
  if (($environment == 'production') and ($facts['vagrant'] != '1')) {
    [$repo_fqdn, $repo_legacy_fqdn].each |String $domain| {
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
}
