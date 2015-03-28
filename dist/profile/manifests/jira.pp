# Run containerized JIRA to serve issues.jenkins-ci.org
class profile::jira (
  # all injected from hiera
  $image_tag,
) {
  # as a preparation, deploying mock-webapp and not the real jira

  include profile::docker
  include profile::apache-misc

  file { '/var/log/apache2/issues.jenkins-ci.org':
    ensure => directory,
  }

  docker::image { 'jenkinsciinfra/mock-webapp':
    image_tag => $image_tag,
  }

  docker::run { 'jira':
    command  => undef,
    ports    => ['8080:8080'],
    image    => "jenkinsciinfra/mock-webapp:${image_tag}",
    volumes  => ['/srv/jira/home:/srv/jira/home'],
  }

  apache::vhost { 'issues.jenkins-ci.org':
    servername      => 'issues.jenkins-ci.org',
    vhost_name      => '*',
    port            => '443',
    access_log      => false,
    error_log_file  => 'issues.jenkins-ci.org/error.log',
    log_level       => 'warn',
    custom_fragment => template("${module_name}/jira/vhost.conf"),

    notify          => Service['apache2'],
    require         => File['/var/log/apache2/issues.jenkins-ci.org'],
  }
}
