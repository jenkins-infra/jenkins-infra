#   Class: profile::kubernetes::resources::evergreen
#
#   This class deploys the Jenkins Essentials backend service layer, a
#   container which communicates with a provisioned Azure PostgreSQL database
#
class profile::kubernetes::resources::evergreen (
    Array $clusters = $profile::kubernetes::params::clusters,
    Array $domain_alias = [],
    String $image_tag = 'latest',
    String $domain_name = 'evergreen.jenkins.io',
    String $jwt_secret = 'default-jwt-secret',
    String $internal_api_secret = 'default-internal-api-secret',
    String $sentry_url = 'http://example.com/sentry',
    String $postgres_url = '',
) inherits profile::kubernetes::params {

  require profile::kubernetes::kubectl
  require profile::kubernetes::resources::nginx
  require profile::kubernetes::resources::lego

  $clusters.each | $cluster | {
    $context = $cluster['clustername']

    file { "${profile::kubernetes::params::resources}/${context}/evergreen":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    profile::kubernetes::apply { "evergreen/namespace.yaml on ${context}":
      context  => $context,
      resource => 'evergreen/namespace.yaml'
    }

    profile::kubernetes::apply { "evergreen/service.yaml on ${context}":
      context  => $context,
      resource => 'evergreen/service.yaml'
    }

    profile::kubernetes::apply { "evergreen/secret.yaml on ${context}":
      context    => $context,
      parameters => {
        'postgres_url' => base64('encode', $postgres_url, 'strict'),
        'jwt_secret' => base64('encode', $jwt_secret, 'strict'),
        'internal_api_secret' => base64('encode', $internal_api_secret, 'strict'),
        'sentry_url' => base64('encode', $sentry_url, 'strict'),
      },
      resource   => 'evergreen/secret.yaml'
    }

    profile::kubernetes::apply { "evergreen/ingress-tls.yaml on ${context}":
      context    => $context,
      parameters => {
        'url'     => $domain_name,
        'aliases' => $domain_alias
      },
      resource   =>  'evergreen/ingress-tls.yaml'
    }

    profile::kubernetes::apply { "evergreen/deployment.yaml on ${context}":
      context    => $context,
      parameters => {
        'image_tag' =>  $image_tag
      },
      resource   => 'evergreen/deployment.yaml'
    }

    profile::kubernetes::reload { "evergreen pods on ${context}":
      app        => 'evergreen',
      context    => $context,
      depends_on => [
        'evergreen/secret.yaml'
      ]
    }

    profile::kubernetes::backup { "evergreen-tls on ${context}":
      context =>  $context
    }
  }
}
