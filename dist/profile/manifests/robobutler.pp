#
# IRC bot that runs project meeting
# containerized in https://github.com/jenkins-infra/robobutler
#
class profile::robobutler (
  # all injected from hiera
  $nick,
  $password,
  $logdir = '/var/www/meetings.jenkins-ci.org'
) {
  include profile::apachemisc
  include profile::docker

  # Tag is the docker container image tag from our build process
  $tag = 'build12'
  $user = 'butlerbot'

  user { $user:
    # butlerbot user id. hard-coded into butlerbot image
    uid   => '500',
    shell => '/bin/false',
  }

  file { $logdir:
    ensure => directory,
    owner  => $user,
    mode   => '0755',
  }

  file { '/etc/butlerbot':
    ensure => directory,
    owner  => $user,
  }

  file { '/etc/butlerbot/main.conf':
    owner   => $user,
    mode    => '0600',
    content => "export NICK=${nick}\nexport PASSWORD=${password}\nexport HTML_DIR=${logdir}",
    require => File['/etc/butlerbot'],
    notify  => Service['docker-butlerbot'],
  }

  docker::image { 'jenkinsciinfra/butlerbot':
    image_tag => $tag,
  }

  docker::run { 'butlerbot':
    command => undef,
    image   => "jenkinsciinfra/butlerbot:${tag}",
    volumes => ["${logdir}:${logdir}", '/etc/butlerbot:/etc/butlerbot'],
    require => File['/etc/butlerbot/main.conf'],
  }

  file { '/var/log/apache2/meetings.jenkins-ci.org':
    ensure => directory,
  }

  apache::vhost { 'meetings.jenkins-ci.org':
    servername                   => 'meetings.jenkins-ci.org',
    docroot                      => $logdir,
    port                         => '80',
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    access_log                   => false,
    error_log_file               => 'meetings.jenkins-ci.org/error.log',
    log_level                    => 'warn',
    custom_fragment              => 'CustomLog "|/usr/bin/rotatelogs /var/log/apache2/meetings.jenkins-ci.org/access.log.%Y%m%d%H%M%S 604800" reverseproxy_combined',
    notify                       => Service['apache2'],
    require                      => File['/var/log/apache2/meetings.jenkins-ci.org'],
  }
}
