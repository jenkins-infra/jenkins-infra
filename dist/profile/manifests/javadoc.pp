#
# javadoc profile for managing the basic statically hosted site for javadocs
#
# https://github.com/jenkins-infra/javadoc/
class profile::javadoc(
  $site_root = '/srv/javadoc',
) {
  include ::apache
  include profile::apachemisc

  file { $site_root:
    ensure  => 'absent',
  }

  cron { 'update javadoc.jenkins.io':
    ensure  => 'absent',
  }

  $apache_log_dir = '/var/log/apache2/javadoc.jenkins.io'
  file { $apache_log_dir:
    ensure => 'absent',
  }

  apache::vhost { 'javadoc.jenkins.io':
    ensure  => 'absent',
    docroot => $site_root,
  }
}
