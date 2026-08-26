#
# Profile to provision the necessary "census" host setup
#
# A "census" host processes the anonymized user data from a "usage" host into infra-statistics
class profile::census (
  String $postgres_password,
  Stdlib::Absolutepath $data_disk    = '/srv/census',
) {
  include stdlib # Required to allow using stlib methods and custom datatypes
  include profile::golang # Required for the stats CLI

  file { $data_disk:
    ensure => directory,
    mode   => '0755',
    owner  => root,
    group  => root,
  }

  $census_db_data_dir = "${data_disk}/census-db-data"

  file { $census_db_data_dir:
    ensure  => directory,
    mode    => '0770',
    owner   => 999,
    group   => 999,
    require => File[$data_disk],
  }

  # Run postgres using Docker
  include profile::docker
  docker::run { 'census-db':
    image         => 'postgres:18',
    env           => [
      'POSTGRES_DB=census-data',
      'POSTGRES_USER=census',
      "POSTGRES_PASSWORD=${postgres_password}",
    ],
    ports         => ['127.0.0.1:5432:5432'],
    volumes       => [
      "${census_db_data_dir}:/var/lib/postgresql:rw",
    ],
    pull_on_start => true,
    require       => [Class['profile::docker'],File[$census_db_data_dir]],
  }

  # Set up SSH access to usage.jenkins.io in order to retrieve stats from it
  file { '/root/.ssh':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  file { '/root/.ssh/id_usage':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => lookup('usage_ssh_privkey'),
    require => File['/root/.ssh'],
  }

  file { '/root/.ssh/config':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => "
Host usage.jenkins.io
    User usagestats
    IdentityFile /root/.ssh/id_usage
",
    require => [
      File['/root/.ssh/id_usage'],
    ],
  }
}
