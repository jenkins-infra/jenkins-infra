#
# javadoc profile for managing the basic statically hosted site for javadocs
#
# https://github.com/jenkins-infra/javadoc/
class profile::javadoc(
  $site_root = '/srv/javadoc',
  $remote_archive = 'https://ci.jenkins.io/job/Infra/job/javadoc/job/master/lastSuccessfulBuild/artifact/build/javadoc-site.tar.bz2',
) {
  include ::apache
  include profile::apachemisc

  $user = 'www-data'

  file { $site_root:
    ensure  => directory,
    owner   => $user,
    group   => 'www-data',
    recurse => true
  }

  cron { 'update javadoc.jenkins.io':
    ensure  => present,
    command => "cd /tmp && /usr/bin/wget ${remote_archive} && /bin/tar -C ${site_root} --strip 1 --overwrite --owner=${user} -xjf javadoc-site.tar.bz2 ; rm -f javadoc-site.tar.bz2",
    user    => $user,
    hour    => 4,
    minute  => 0,
    weekday => 1,
  }

  $apache_log_dir = '/var/log/apache2/javadoc.jenkins.io'
  file { $apache_log_dir:
    ensure => directory,
    owner  => $user,
    group  => 'www-data',
  }

  apache::vhost { 'javadoc.jenkins.io':
    serveraliases   => [
      'javadoc.jenkins-ci.org',
    ],
    docroot         => $site_root,
    port            => 80,
    access_log_pipe => "|/usr/bin/rotatelogs ${apache_log_dir}/access.log.%Y%m%d%H%M%S 604800",
    error_log_file  => 'javadoc.jenkins.io/error.log',
    require         => [
      File[$site_root],
      File[$apache_log_dir],
    ],
  }
}
