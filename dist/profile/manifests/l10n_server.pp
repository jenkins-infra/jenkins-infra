#
# Accept submissions from the translation plugin
# containerized in https://github.com/jenkins-infra/l10n-server
class profile::l10n_server (
  # Parameters supplied by Hiera
  $image_tag = 'latest',
) {
  include profile::docker
  include profile::apachemisc

  validate_string($image_tag)
  $user = 'l10n'
  $dir = "/srv/${user}"
  $uid = '2003'
  $image = 'jenkinsciinfra/l10n-server'

  docker::image { $image:
    image_tag => $image_tag,
  }

  docker::run { 'l10n':
    volumes  => ["${dir}:/var/l10n"
    ],
    ports    => ['8082:8080'],
    username => $uid,
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
    uid        => $uid,
    managehome => true,
  }

  # docroot is required for apache::vhost but should never be used because
  # we're proxying everything here
  $docroot = '/var/www/html'

  apache::vhost { 'l10n.jenkins.io':
    serveraliases => [
      'l10n.jenkins-ci.org',
    ],
    port          => '80',
    docroot       => $docroot,
    proxy_pass    => [
      {
        path         => '/',
        url          => 'http://localhost:8082/',
        reverse_urls => 'http://localhost:8082/',
      },
    ],
  }
}
