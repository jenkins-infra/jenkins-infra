# Run containerized Confluence to serve wiki.jenkins-ci.org
# see https://github.com/jenkins-infra/confluence for how the container is put together
#
# this class puts apache virtual host for wiki.jenkins-ci.org, which forwards requests to
#
class profile::confluence (
  $image_tag,         # tag of confluence container
  $cache_image_tag,   # tag of confluence cache container
  $database_url,      # JDBC URL that represents the database backend
) {
  # as a preparation, deploying mock-webapp and not the real confluence

  include profile::atlassian
  include apache::mod::headers
  include apache::mod::rewrite
  include profile::apachemisc

  account { 'wiki':
    home_dir => '/srv/wiki',
    groups   => [ 'sudo', 'users' ],
    uid      => 2000,   # this value must match what's in the 'confluence' docker container
    gid      => 2000,
    comment  => 'Runs confluence',
  }

  file { '/var/log/apache2/wiki.jenkins-ci.org':
    ensure => directory,
    group  => $profile::atlassian::group_name,
  }

  file { '/srv/wiki/home':
    ensure => directory,
    # confluence container is baked with UID=1000 & GID=1001
    owner  => 'wiki',
    group  => $profile::atlassian::group_name,
  }

  file { '/srv/wiki/docroot':
    ensure => directory,
    group  => $profile::atlassian::group_name,
  }

  file { '/srv/wiki/docroot/robots.txt':
    ensure => directory,
    owner  => 'wiki',
    mode   => '0755',
    group  => $profile::atlassian::group_name,
    source => 'puppet:///modules/profile/confluence/robots.txt',
  }

  $ldap_password = hiera('profile::ldap::admin_password')
  file { '/srv/wiki/container.env':
    content => join([
        'LDAP_HOST=ldap.jenkins.io',
        "LDAP_PASSWORD=${ldap_password}",
        "DATABASE_URL=${database_url}"
      ], "\n"),
    mode    => '0600',
  }

  docker::image { 'jenkinsciinfra/confluence':
    image_tag => $image_tag,
  }

  docker::run { 'confluence':
    command         => undef,
    ports           => ['8081:8080', '8091:8091'],
    image           => "jenkinsciinfra/confluence:${image_tag}",
    volumes         => ['/srv/wiki/home:/srv/wiki/home', '/srv/wiki/cache:/srv/wiki/cache'],
    env_file        => '/srv/wiki/container.env',
    restart_service => true,
    require         => File['/srv/wiki/container.env'],
  }

  docker::image { 'jenkinsciinfra/confluence-cache':
    image_tag => $cache_image_tag,
  }

  docker::run { 'confluence-cache':
    command         => undef,
    ports           => ['127.0.0.1:8009:8080'],
    image           => "jenkinsciinfra/confluence-cache:${cache_image_tag}",
    volumes         => ['/srv/wiki/cache:/cache'],
    links           => ['confluence'],
    # The hostname `confluence` should be ensured by the --link option passed
    # to the docker run command
    env             => ['TARGET=http://confluence:8080'],
    restart_service => true,
  }

  ### to put maintenance screen up, comment out the following and comment in the apache::vhost for https://jenkins-ci.org
  ### #if
  #file { '/etc/apache2/sites-enabled/25-wiki.jenkins-ci.org.conf':
  #  ensure => 'link',
  #  target => '/etc/apache2/sites-available/wiki.jenkins-ci.org.maintenance.conf',
  #}
  ### #else
  apache::vhost { 'wiki.jenkins-ci.org':
    port            => '443',
    docroot         => '/srv/wiki/docroot',
    access_log      => false,
    error_log_file  => 'wiki.jenkins-ci.org/error.log',
    log_level       => 'warn',
    custom_fragment => template("${module_name}/confluence/vhost.conf"),

    notify          => Service['apache2'],
    require         => File['/var/log/apache2/wiki.jenkins-ci.org'],
  }
  ### #endif

  apache::vhost { 'wiki.jenkins-ci.org non-ssl':
    # redirect non-SSL to SSL
    servername      => 'wiki.jenkins-ci.org',
    port            => '80',
    docroot         => '/srv/wiki/docroot',
    access_log_pipe => '/dev/null',
    redirect_status => 'temp',
    redirect_dest   => 'https://wiki.jenkins-ci.org/'
  }

  profile::apachemaintenance { 'wiki.jenkins-ci.org':
  }

  profile::datadog_check { 'confluence-http-check':
    checker => 'http_check',
    source  => 'puppet:///modules/profile/confluence/http_check.yaml',
  }

  profile::datadog_check { 'confluence-process-check':
    checker => 'process',
    source  => 'puppet:///modules/profile/confluence/process_check.yaml',
  }

  host { 'wiki.jenkins-ci.org':
    ip => '127.0.0.1',
  }

  firewall {
    '299 allow synchrony for Confluence':
      proto  => 'tcp',
      port   => 8091,
      action => 'accept',
  }
}
