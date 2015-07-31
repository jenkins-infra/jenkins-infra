# Run containerized JIRA to serve issues.jenkins-ci.org
# see https://github.com/jenkins-infra/jira for how the container is put together
class profile::jira (
  # all injected from hiera
  $image_tag,
  $database_url,  # JDBC URL that represents that database backend
) {
  # as a preparation, deploying mock-webapp and not the real jira

  include profile::atlassian
  include profile::apache-misc

  account { 'jira':
    home_dir => '/srv/jira',
    groups   => ['sudo', 'users'],
    uid      => 2001,   # this value must match what's in the 'jira' docker container
    gid      => 2001,
    comment  => 'Runs JIRA',
  }

  file { '/var/log/apache2/issues.jenkins-ci.org':
    ensure => directory,
    group  => $profile::atlassian::group_name,
  }

  file { '/srv/jira/home':
    ensure  => directory,
    require => File['/srv/jira'],
    owner   => 'jira',
    group   => $profile::atlassian::group_name,
  }

  file { '/srv/jira/docroot':
    ensure  => directory,
    require => File['/srv/jira'],
    group   => $profile::atlassian::group_name,
  }

  # JIRA stores LDAP access information in database, not in file
  file { '/srv/jira/container.env':
    content => join([
        "DATABASE_URL=${database_url}"
      ], '\n'),
    mode    => '0600',
  }

  if $::vagrant { # only for testing
    docker::run { 'jiradb':
      image           => 'mariadb',
      env             => ['MYSQL_ROOT_PASSWORD=s3cr3t','MYSQL_USER=jira','MYSQL_PASSWORD=raji','MYSQL_DATABASE=jiradb'],
      restart_service => true,
      use_name        => true,
      command         => undef,
    }
    $jira_links = ['jiradb:db']
  } else {
    $jira_links = undef
  }

  docker::image { 'jenkinsciinfra/jira':
    image_tag => $image_tag,
  }

  docker::run { 'jira':
    command         => undef,
    ports           => ['8080:8080'],
    image           => "jenkinsciinfra/jira:${image_tag}",
    volumes         => ['/srv/jira/home:/srv/jira/home'],
    env_file        => '/srv/jira/container.env',
    restart_service => true,
    use_name        => true,
    require         => File['/srv/jira/container.env'],
    links           => $jira_links,
  }

  ### to put maintenance screen up, comment out the following and comment in the apache::vhost for https://jenkins-ci.org
  ### #if
  file { '/etc/apache2/sites-enabled/25-issues.jenkins-ci.org.conf':
    ensure => 'link',
    target => '/etc/apache2/sites-available/issues.jenkins-ci.org.maintenance.conf',
  }
  ### #else
  #apache::vhost { 'issues.jenkins-ci.org':
  #  port            => '443',
  #  docroot         => '/srv/jira/docroot',
  #  access_log      => false,
  #  error_log_file  => 'issues.jenkins-ci.org/error.log',
  #  log_level       => 'warn',
  #  custom_fragment => template("${module_name}/jira/vhost.conf"),
  #
  #  notify          => Service['apache2'],
  #  require         => File['/var/log/apache2/issues.jenkins-ci.org'],
  #}
  ### #endif
  apache::vhost { 'issues.jenkins-ci.org non-ssl':
    # redirect non-SSL to SSL
    servername      => 'issues.jenkins-ci.org',
    port            => '80',
    docroot         => '/srv/jira/docroot',
    redirect_status => 'temp',
    redirect_dest   => 'https://issues.jenkins-ci.org/'
  }

  profile::apache-maintenance { 'issues.jenkins-ci.org':
  }

  profile::datadog_check { 'jira-http-check':
    checker   => 'http_check',
    source    => 'puppet:///modules/profile/jira/http_check.yaml',
  }

  profile::datadog_check { 'jira-process-check':
    checker   => 'process',
    source    => 'puppet:///modules/profile/jira/process_check.yaml',
  }

  host { 'issues.jenkins-ci.org':
    ip => '127.0.0.1',
  }
}
