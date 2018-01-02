# Deploy datadog resources on kubernetes cluster
#   Class: profile::kubernetes::resources::datadog
#
#   This class deploy a datadog agent on each kubernetes node
#
#   Parameters:
#     $apiKey:
#       Contain datadog api key.
#       Used in secret template
class profile::kubernetes::resources::datadog (
    String $api_key  = $::datadog_agent::api_key,
    Array $clusters = $profile::kubernetes::params::clusters
  ) inherits profile::kubernetes::params {

  include ::stdlib
  require profile::kubernetes::kubectl

  $clusters.each | $cluster | {
    $context = $cluster['clustername']

    file { "${profile::kubernetes::params::resources}/${context}/datadog":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    profile::kubernetes::apply { "datadog/secret.yaml on ${context}":
      context    => $context,
      parameters => {
          'api_key' => base64('encode', $api_key, 'strict')
      },
      resource   => 'datadog/secret.yaml'
    }

    profile::kubernetes::apply { "datadog/daemonset.yaml on ${context}":
      context  => $context,
      resource => 'datadog/daemonset.yaml'
    }
    profile::kubernetes::apply { "datadog/deployment.yaml on ${context}":
      context  => $context,
      resource => 'datadog/deployment.yaml'
    }

    # As secret changes do not trigger pods update,
    # we must reload pods 'manually' to use the newly updated secret
    # If we delete a pod defined by daemonset,
    # this daemonset will recreate a new one
    profile::kubernetes::reload { "datadog pods on ${context}":
      context    => $context,
      app        => 'datadog',
      depends_on => [
        'datadog/secret.yaml',
        'datadog/daemonset.yaml',
      ]
    }
  }
}
