#
# Basic profile for deploying the plugin-site container onto a host with the
# appropriate reverse proxying via Apache
class profile::pluginsite(
  $image_tag = 'latest',
  $pluginsite_fqdn = 'plugins.jenkins.io',
) {
  include profile::docker
  include profile::apachemisc
  include profile::letsencrypt

  validate_string($image_tag)
  validate_string($pluginsite_fqdn)

  $image = 'jenkinsciinfra/plugin-site'
  $docroot = '/srv/pluginsite'
  $apache_log_dir = "/var/log/apache2/${pluginsite_fqdn}"

  docker::image { $image:
    image_tag => $image_tag,
  }

  docker::run { 'pluginsite' :
    image   => "${image}:${image_tag}",
    ports   => ['8080:8080', '5000:5000'],
    env     => [
      'DATA_FILE_URL=https://ci.jenkins.io/job/Infra/job/plugin-site-api/job/generate-data/lastSuccessfulBuild/artifact/plugins.json.gzip',
      "REST_API_URL=https://${pluginsite_fqdn}/api",
    ],
    require => Docker::Image[$image],
  }

  file { [$apache_log_dir, $docroot]:
    ensure => directory,
  }

  profile::datadog_check { 'pluginsite-http-check':
    checker => 'http_check',
    source  => 'puppet:///modules/profile/pluginsite/http_check.yaml',
  }

  apache::vhost { $pluginsite_fqdn:
    port            => 443,
    ssl             => true,
    docroot         => $docroot,
    access_log      => false,
    error_log_file  => "${pluginsite_fqdn}/error.log",
    custom_fragment => '
  ProxyRequests Off
  ProxyPreserveHost Off
  ProxyPassMatch ^/api/(.*) http://localhost:8080/$1
  ProxyPassReverse ^/api/(.*) http://localhost:8080/$1
  ProxyPass / http://localhost:5000/
  ProxyPassReverse / http://localhost:5000/
',
    require         => [
      File[$apache_log_dir],
      File[$docroot],
    ],
    notify          => Service['apache2'],
  }

  apache::vhost { "${pluginsite_fqdn} unsecured":
    servername      => $pluginsite_fqdn,
    port            => '80',
    docroot         => $docroot,
    redirect_status => 'permanent',
    redirect_dest   => "https://${pluginsite_fqdn}/",
  }


  # This is a *hack* to cope with the front-end application using the same URL
  # for internal requests to the backend API while giving that URL to
  # browser-connected clients
  host { $pluginsite_fqdn:
    ip => '127.0.0.1',
  }

  # We can only acquire certs in production due to the way the letsencrypt
  # challenge process works
  if (($::environment == 'production') and ($::vagrant != '1')) {
    letsencrypt::certonly { $pluginsite_fqdn:
        domains     => [$pluginsite_fqdn],
        plugin      => 'apache',
        manage_cron => true,
    }

    Apache::Vhost <| title == $pluginsite_fqdn |> {
      # When Apache is upgraded to >= 2.4.8 this should be changed to
      # fullchain.pem
      ssl_key       => "/etc/letsencrypt/live/${pluginsite_fqdn}/privkey.pem",
      ssl_cert      => "/etc/letsencrypt/live/${pluginsite_fqdn}/cert.pem",
      ssl_chain     => "/etc/letsencrypt/live/${pluginsite_fqdn}/chain.pem",
    }
  }
}
