#
# Server side of the community rating data
# containerized in https://github.com/jenkins-infra/infra-rating
class profile::rating (
  # Parameters supplied by Hiera
  $image_tag = 'latest',
) {
  include profile::docker

  validate_string($image_tag)
  $image = 'jenkinsciinfra/rating'
  $config = '/etc/rating.conf'

  docker::image { $image:
    image_tag => $image_tag,
  }

  docker::run { 'rating':
    image   => "${image}:${image_tag}",
    volumes => ["${config}:/config/dbconfig.php"
    ],
    require => [Docker::Image[$image],
                File[$config],
    ],
  }

  # The File[/etc/init/docker-ircbot.conf] resource is declared by the
  # module, but we still need to punt the container if the config changes
  File <| title == '/etc/init/docker-rating.conf' |> {
    notify  => Service['docker-rating'],
  }

  file { $config:
    content => hiera('profile::rating::dbconfig'),
    mode    => '0600',
    notify  => Service['docker-rating'],
  }

  # convenient to interact with database
  package { 'postgresql-client':
    ensure => present,
  }
}
