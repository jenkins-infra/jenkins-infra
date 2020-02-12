# Run containerized Confluence to serve wiki.jenkins-ci.org
# see https://github.com/jenkins-infra/confluence for how the container is put together
#
# this class puts apache virtual host for wiki.jenkins-ci.org, which forwards requests to
#
class profile::confluence (
  $image_tag,         # tag of confluence container
  $cache_image_tag,   # tag of confluence cache container
  String $database_url = '',      # JDBC URL that represents the database backend
  String $database_user = '',     # JDBC password
  String $database_password = '', # Database password
  String $database_jdbc_url = ''  # JDBC URL without user/password
) {
  # as a preparation, deploying mock-webapp and not the real confluence

  include profile::atlassian
  include apache::mod::headers
  include apache::mod::rewrite
  include profile::apachemisc
  include profile::letsencrypt

  account { 'wiki':
    home_dir => '/srv/wiki',
    groups   => [ 'sudo', 'users' ],
    uid      => 2000,   # this value must match what's in the 'confluence' docker container
    gid      => 2000,
    comment  => 'Runs confluence',
  }

  file { '/usr/local/bin/access_logs_reporter.sh':
    ensure => file,
    mode   => '0755',
    owner  => 'root',
    source => 'puppet:///modules/profile/confluence/report_last_log.sh',
  }

  cron { 'access_logs_reporter.sh':
    command => '/usr/local/bin/access_logs_reporter.sh',
    present => present,
    user    => 'root',
    hour    => 7,
    minute  => 0,
  }

  file { '/var/www/html/reports':
    ensure => directory,
    mode   => '0755',
    owner  => 'root',
  }

  file { '/var/log/apache2/wiki.jenkins-ci.org':
    ensure => directory,
    group  => $profile::atlassian::group_name,
  }

  file { '/var/log/apache2/wiki.jenkins.io':
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

  $ldap_password = lookup('profile::ldap::admin_password')
  file { '/srv/wiki/container.env':
    content => join([
        'LDAP_HOST=ldap.jenkins.io',
        "LDAP_PASSWORD=${ldap_password}",
        "DB_JDBC_URL=${database_jdbc_url}",
        "DB_USER=${database_user}",
        "DB_PASSWORD=${database_password}"
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

  apache::vhost { 'wiki.jenkins-ci.org':
    ssl             => true,
    port            => '443',
    docroot         => '/srv/wiki/docroot',
    access_log_pipe => '/dev/null',
    redirect_status => 'permanent',
    redirect_dest   => 'https://wiki.jenkins.io/',
    require         => Apache::Vhost['wiki.jenkins.io'],
    notify          => Service['apache2'],
  }

  apache::vhost { 'wiki.jenkins-ci.org non-ssl':
    # redirect non-SSL to SSL
    servername      => 'wiki.jenkins-ci.org',
    port            => '80',
    docroot         => '/srv/wiki/docroot',
    access_log_pipe => '/dev/null',
    redirect_status => 'permanent',
    redirect_dest   => 'https://wiki.jenkins.io/'
  }

  apache::vhost { 'wiki.jenkins.io':
    port            => '443',
    ssl             => true,
    docroot         => '/srv/wiki/docroot',
    access_log      => false,
    error_log_file  => 'wiki.jenkins.io/error.log',
    log_level       => 'warn',
    custom_fragment => template("${module_name}/confluence/vhost.conf"),

    notify          => Service['apache2'],
    require         => File['/var/log/apache2/wiki.jenkins.io'],
  }
  ### #endif

  apache::vhost { 'wiki.jenkins.io non-ssl':
    # redirect non-SSL to SSL
    servername      => 'wiki.jenkins.io',
    port            => '80',
    docroot         => '/srv/wiki/docroot',
    redirect_status => 'permanent',
    redirect_dest   => 'https://wiki.jenkins.io/'
  }

  profile::apachemaintenance { 'wiki.jenkins.io':
  }

  profile::datadog_check { 'confluence-process-check':
    checker => 'process',
    source  => 'puppet:///modules/profile/confluence/process_check.yaml',
  }

  host { 'wiki.jenkins.io':
    ip => '127.0.0.1',
  }

  firewall {
    '299 allow synchrony for Confluence':
      proto  => 'tcp',
      dport  => 8091,
      action => 'accept',
  }

  # We can only acquire certs in production due to the way the letsencrypt
  # challenge process works
  if (($::environment == 'production') and ($::vagrant != '1')) {
    letsencrypt::certonly { 'wiki.jenkins.io':
        domains     => ['wiki.jenkins.io','wiki.jenkins-ci.org'],
        plugin      => 'apache',
        manage_cron => true,
    }
    Apache::Vhost <| title == 'wiki.jenkins.io' |> {
    # When Apache is upgraded to >= 2.4.8 this should be changed to
    # fullchain.pem
      ssl_key       => '/etc/letsencrypt/live/wiki.jenkins.io/privkey.pem',
      ssl_cert      => '/etc/letsencrypt/live/wiki.jenkins.io/cert.pem',
      ssl_chain     => '/etc/letsencrypt/live/wiki.jenkins.io/chain.pem',
    }
    Apache::Vhost <| title == 'wiki.jenkins-ci.org' |> {
      ssl_key       => '/etc/letsencrypt/live/wiki.jenkins.io/privkey.pem',
      ssl_cert      => '/etc/letsencrypt/live/wiki.jenkins.io/cert.pem',
      ssl_chain     => '/etc/letsencrypt/live/wiki.jenkins.io/chain.pem',
    }

  }
}
