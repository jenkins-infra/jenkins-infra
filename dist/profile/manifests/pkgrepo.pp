#
# Manage yum and apt repositories for Jenkins
class profile::pkgrepo (
  $docroot      = '/var/www/pkg.jenkins.io',
  $release_root = '/srv/releases/jenkins',
  $mirror_fqdn  = 'mirrors.jenkins.io'
) {
  include ::stdlib
  include ::apache

  validate_string($docroot)
  validate_string($release_root)

  include profile::apachemisc
  include profile::firewall
  include profile::letsencrypt

  file { $docroot:
    ensure => directory,
    owner  => 'root',
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
    require => File[$docroot],
  }

  file { suffix($repos, '/jenkins-ci.org.key'):
    ensure  => present,
    source  => "puppet:///modules/${module_name}/pkgrepo/jenkins-ci.org.key",
    require => File[$docroot],
  }

  profile::redhat_repo { ['redhat', 'redhat-stable', 'redhat-rc', 'redhat-stable-rc']:
    ensure      => present,
    docroot     => $docroot,
    mirror_fqdn => $mirror_fqdn,
    require     => File[$repos],
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

  apache::vhost { 'pkg.jenkins.io':
    serveraliases => [
      'pkg.jenkins-ci.org',
    ],
    port          => 443,
    ssl           => true,
    docroot       => $docroot,
    require       => File[$docroot],
  }

  apache::vhost { 'pkg.jenkins.io unsecured':
    servername      => 'pkg.jenkins.io',
    serveraliases   => [
      'pkg.jenkins-ci.org',
    ],
    port            => 80,
    docroot         => $docroot,
    redirect_status => 'permanent',
    redirect_dest   => 'https://pkg.jenkins.io/',
    require         => Apache::Vhost['pkg.jenkins.io'],
  }


  # We can only acquire certs in production due to the way the letsencrypt
  # challenge process works
  if (($::environment == 'production') and ($::vagrant != '1')) {
    letsencrypt::certonly { 'pkg.jenkins.io':
      domains     => ['pkg.jenkins.io'],
      plugin      => 'apache',
      manage_cron => true,
    }
  }
}
