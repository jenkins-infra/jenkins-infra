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

  include profile::docker
  include profile::apache-misc

  account {
  'wiki':
    home_dir => '/srv/wiki',
    groups   => [ 'sudo', 'users' ],
    uid      => 2000,   # this value must match what's in the 'confluence' docker container
    gid      => 2000,
    comment  => 'Runs confluence',
  }

  file { '/var/log/apache2/wiki.jenkins-ci.org':
    ensure => directory,
  }
  file { '/srv/wiki/home':
    ensure  => directory,
    # confluence container is baked with UID=1000 & GID=1001
    owner   => 'wiki',
    group   => 'wiki',
  }
  file { '/srv/wiki/docroot':
    ensure  => directory,
  }

  $ldap_password = hiera('profile::ldap::admin_password')
  file { '/srv/wiki/container.env':
    content => join([
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
    ports           => ['8081:8080'],
    image           => "jenkinsciinfra/confluence:${image_tag}",
    volumes         => ['/srv/wiki/home:/srv/wiki/home', '/srv/wiki/cache:/srv/wiki/cache'],
    env_file        => '/srv/wiki/container.env',
    restart_service => true,
    use_name        => true,
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
    env             => ['TARGET=http://172.17.42.1:8081'],
    restart_service => true,
    use_name        => true,
  }

  apache::mod { 'proxy':
  }

  apache::mod { 'proxy_http':
  }

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

  apache::vhost { 'wiki.jenkins-ci.org non-ssl':
    # redirect non-SSL to SSL
    servername      => 'wiki.jenkins-ci.org',
    port            => '80',
    docroot         => '/srv/wiki/docroot',
    redirect_status => 'temp',
    redirect_dest   => 'https://wiki.jenkins-ci.org/'
  }

  firewall {
    '400 allow http':
      proto  => 'tcp',
      port   => 80,
      action => 'accept',
  }

  firewall {
    '401 allow https':
      proto  => 'tcp',
      port   => 443,
      action => 'accept',
  }

  profile::apache-maintenance { 'wiki.jenkins-ci.org':
  }

  host { 'wiki.jenkins-ci.org':
    ip => '127.0.0.1',
  }
}
