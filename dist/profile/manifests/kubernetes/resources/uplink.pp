#   Class: profile::kubernetes::resources::uplink
#
#   This class deploys the Uplink app which is a simple container which
#   communicates with a provisioned Azure PostgreSQL database
#
class profile::kubernetes::resources::uplink (
    Array $clusters = $profile::kubernetes::params::clusters,
    Array $domain_alias = [],
    String $image_tag = 'latest',
    String $domain_name = 'uplink.jenkins.io',
    String $client_id = 'c2247b85aa837ac179cd',
    String $client_secret = '',
    String $sentry_dsn = '',
    String $postgres_url = '',
) inherits profile::kubernetes::params {

  require profile::kubernetes::kubectl
  require profile::kubernetes::resources::nginx
  require profile::kubernetes::resources::lego

  $clusters.each | $cluster | {
    $context = $cluster['clustername']

    file { "${profile::kubernetes::params::resources}/${context}/uplink":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    profile::kubernetes::apply { "uplink/namespace.yaml on ${context}":
      context  => $context,
      resource => 'uplink/namespace.yaml'
    }

    profile::kubernetes::apply { "uplink/service.yaml on ${context}":
      context  => $context,
      resource => 'uplink/service.yaml'
    }

    profile::kubernetes::apply { "uplink/secret.yaml on ${context}":
      context    => $context,
      parameters => {
        'postgres_url'  => base64('encode', $postgres_url, 'strict'),
        'client_id'     => base64('encode', $client_id, 'strict'),
        'client_secret' => base64('encode', $client_secret, 'strict'),
        'sentry_dsn'    => base64('encode', $sentry_dsn, 'strict'),
      },
      resource   => 'uplink/secret.yaml'
    }

    profile::kubernetes::apply { "uplink/ingress-tls.yaml on ${context}":
      context    => $context,
      parameters => {
        'url'     => $domain_name,
        'aliases' => $domain_alias
      },
      resource   =>  'uplink/ingress-tls.yaml'
    }

    profile::kubernetes::apply { "uplink/deployment.yaml on ${context}":
      context    => $context,
      parameters => {
        'image_tag' =>  $image_tag
      },
      resource   => 'uplink/deployment.yaml'
    }

    profile::kubernetes::reload { "uplink pods on ${context}":
      app        => 'uplink',
      context    => $context,
      depends_on => [
        'uplink/secret.yaml'
      ]
    }

    profile::kubernetes::backup { "uplink-tls on ${context}":
      context =>  $context
    }
  }
}
