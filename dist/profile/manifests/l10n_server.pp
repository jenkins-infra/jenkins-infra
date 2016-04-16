#
# Accept submissions from the translation plugin
# containerized in https://github.com/jenkins-infra/l10n-server
class profile::l10n_server (
  # Parameters supplied by Hiera
  $image_tag = 'latest',
) {
  include profile::docker

  validate_string($image_tag)
  $user = 'l10n'
  $dir = "/srv/${user}"
  $image = 'jenkinsciinfra/l10n-server'

  docker::image { $image:
    image_tag => $image_tag,
  }

  docker::run { 'l10n':
    volumes  => ["${dir}:/var/l10n"
    ],
    username => 'l10n',
    image    => "${image}:${image_tag}",
    require  => [Docker::Image[$image],
    ],
  }

  # The File[/etc/init/docker-ircbot.conf] resource is declared by the
  # module, but we still need to punt the container if the config changes
  File <| title == '/etc/init/docker-l10n.conf' |> {
    notify  => Service['docker-l10n'],
  }

  user { $user:
    shell      => '/bin/false',
    home       => $dir,
    managehome => true,
  }
}
