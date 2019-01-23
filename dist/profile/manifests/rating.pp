#
# Server side of the community rating data
# containerized in https://github.com/jenkins-infra/infra-rating
class profile::rating (
  # Parameters supplied by Hiera
  $image_tag = 'latest',
) {
  include profile::docker
  include profile::apachemisc
  include profile::letsencrypt

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
    ports   => ['8083:80'],
    require => [Docker::Image[$image],
                File[$config],
    ],
  }

  file { $config:
    content => lookup('profile::rating::dbconfig'),
    mode    => '0644',
    notify  => Service['docker-rating'],
  }

  # convenient to interact with database
  package { 'postgresql-client':
    ensure => present,
  }


  # docroot is required for apache::vhost but should never be used because
  # we're proxying everything here
  $docroot = '/var/www/html'

  apache::vhost { 'rating.jenkins.io':
    port       => '443',
    ssl        => true,
    ssl_key    => '/etc/letsencrypt/live/rating.jenkins.io/privkey.pem',
    # When Apache is upgraded to >= 2.4.8 this should be changed to
    # fullchain.pem
    ssl_cert   => '/etc/letsencrypt/live/rating.jenkins.io/cert.pem',
    ssl_chain  => '/etc/letsencrypt/live/rating.jenkins.io/chain.pem',
    docroot    => $docroot,
    proxy_pass => [
      {
        path         => '/',
        url          => 'http://localhost:8083/',
        reverse_urls => 'http://localhost:8083/',
      },
    ],
  }

  apache::vhost { 'rating.jenkins.io unsecured':
    servername      => 'rating.jenkins.io',
    port            => '80',
    docroot         => $docroot,
    redirect_status => 'permanent',
    redirect_dest   => 'https://rating.jenkins.io/',
  }

  # We can only acquire certs in production due to the way the letsencrypt
  # challenge process works
  if (($::environment == 'production') and ($::vagrant != '1')) {
    letsencrypt::certonly { 'rating.jenkins.io':
        domains     => ['rating.jenkins.io'],
        plugin      => 'apache',
        manage_cron => true,
    }
  }
}
