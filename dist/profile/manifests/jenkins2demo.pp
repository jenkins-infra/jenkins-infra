#
# Run jenkins 2.0 preview in a Docker container to demo its functionality
class profile::jenkins2demo {
  include profile::docker

  $image = 'jenkinsci/jenkins:2.0-alpha-1'
  $user  = 'jenkins2'
  $uid   = 2002

  docker::image { $image:
  }

  docker::run { 'jenkins2demo':
    username        => $uid,
    volumes         => ['/srv/jenkins2demo:/var/jenkins_home'],
    image           => $image,
    ports           => ['8080:8080'],
    restart_service => true,
    use_name        => true,
    require         => [
      Class['::docker'],
      Docker::Image[$image],
      File['/srv/jenkins2demo'],
      User[$user],
    ],
  }

  account { $user:
    home_dir => '/srv/jenkins2demo',
    uid      => $uid,
    comment  => 'Runs Jenkins 2 demo',
  }
}
