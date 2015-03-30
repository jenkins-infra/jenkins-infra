# Run containerized JIRA to serve issues.jenkins-ci.org
# see https://github.com/jenkins-infra/jira for how the container is put together
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
  file { '/srv/jira/home':
    ensure  => directory,
    recurse => true,
  }
  file { '/srv/jira/docroot':
    ensure  => directory,
    recurse => true,
  }

  docker::image { 'jenkinsciinfra/mock-webapp':
    image_tag => $image_tag,
  }

  docker::run { 'jira':
    command         => undef,
    ports           => ['8080:8080'],
    image           => "jenkinsciinfra/mock-webapp:${image_tag}",
    volumes         => ['/srv/jira/home:/srv/jira/home'],
    env             => ['APP="Jenkins JIRA"'],
    restart_service => true,
  }

  apache::mod { 'proxy':
  }

  apache::mod { 'proxy_http':
  }

  apache::vhost { 'issues.jenkins-ci.org':
    servername      => 'issues.jenkins-ci.org',
    vhost_name      => '*',
    port            => '443',
    ssl             => true,
    docroot         => '/srv/jira/docroot',
    access_log      => false,
    error_log_file  => 'issues.jenkins-ci.org/error.log',
    log_level       => 'warn',
    custom_fragment => template("${module_name}/jira/vhost.conf"),

    notify          => Service['apache2'],
    require         => File['/var/log/apache2/issues.jenkins-ci.org'],
  }
  apache::vhost { 'issues.jenkins-ci.org non-ssl':
    # redirect non-SSL to SSL
    servername      => 'issues.jenkins-ci.org',
    port            => '80',
    docroot         => '/srv/jira/docroot',
    redirect_status => 'temp',
    redirect_dest   => 'https://issues.jenkins-ci.org/'
  }

  host { 'issues.jenkins-ci.org':
    ip => '127.0.0.1',
  }
}
