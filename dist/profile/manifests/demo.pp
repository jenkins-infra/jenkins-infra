#
# Run a demo instance of Jenkins in a Docker container
class profile::demo {
  include profile::docker
  include profile::apache-misc

  $image = 'jenkinsci/jenkins:2.0-alpha-1'
  $user  = 'jenkins2'
  $site  = 'demo'
  $uid   = 2002

  docker::image { $image:
  }

  docker::run { $site:
    username        => $uid,
    volumes         => ['/srv/demo:/var/jenkins_home'],
    image           => $image,
    ports           => ['8080:8080'],
    restart_service => true,
    use_name        => true,
    require         => [
      Class['::docker'],
      Docker::Image[$image],
      File['/srv/demo'],
      User[$user],
    ],
  }

  account { $user:
    home_dir => '/srv/demo',
    uid      => $uid,
    comment  => 'Runs demo',
  }

  file { "/var/log/apache2/${site}.jenkins-ci.org":
    ensure => directory,
  }

  apache::vhost { "${site}.jenkins-ci.org":
    servername      => "${site}.jenkins-ci.org",
    port            => '80',
    docroot         => '/srv/demo/userContent',  # bous
    access_log      => false,
    error_log_file  => "${site}.jenkins-ci.org/error.log",
    log_level       => 'warn',
    custom_fragment => template("${module_name}/demo/vhost.conf"),

    notify          => Service['apache2'],
    require         => [File["/var/log/apache2/${site}.jenkins-ci.org"],
                        Docker::Run[$site]
    ],
  }

  host { "${site}.jenkins-ci.org":
    ip => '127.0.0.1',
  }
}
