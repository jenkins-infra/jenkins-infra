#
# Catchall virtualhosts for the legacy jenkins-ci.org domain
class profile::catchall(
  $docroot = '/var/www/html',
) {
  include ::apache
  include profile::apachemisc

  $apache_log_dir = '/var/log/apache2/jenkins-ci.org'
  $apache_maven_log_dir = '/var/log/apache2/maven.jenkins-ci.org'
  $apache_stats_log_dir = '/var/log/apache2/stats.jenkins-ci.org'
  $docroot_user = 'www-data'

  file { [$apache_maven_log_dir, $apache_log_dir, $apache_stats_log_dir] :
    ensure => absent,
  }

  file { $docroot :
    ensure => absent,
  }

  file { "${docroot}/jenkins.jnlp" :
    ensure  => absent,
  }

  apache::vhost { 'jenkins-ci.org':
    ensure  =>  absent,
    docroot => $docroot,
  }

  apache::vhost { 'jenkins-ci.org unsecured':
    ensure  => absent,
    docroot => $docroot,
  }

  apache::vhost { 'maven.jenkins-ci.org' :
    ensure  => absent,
    docroot => $docroot,
  }

  apache::vhost { 'stats.jenkins-ci.org' :
    ensure  => absent,
    docroot => $docroot
  }

  # Legacy update site compatibility
  ##################################
  file { '/etc/apache2/legacy_cert.key':
    ensure  => absent,
  }

  file { '/etc/apache2/legacy_chain.crt':
    ensure  => absent,
  }

  file { '/etc/apache2/legacy_cert.crt':
    ensure  => absent,
  }
  ##################################
}
