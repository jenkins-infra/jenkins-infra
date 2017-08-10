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
    String $apiKey  = base64('encode', $::datadog_agent::api_key, 'strict'),
  ){
  include ::stdlib
  include profile::kubernetes::params
  require profile::kubernetes::kubectl

  $clusters = $profile::kubernetes::params::clusters

  file { "${profile::kubernetes::params::resources}/datadog":
    ensure => 'directory',
    owner  => $profile::kubernetes::params::user,
  }

  profile::kubernetes::apply { 'datadog/secret.yaml':
    parameters => {
        'apiKey' => $apiKey
    },
  }

  profile::kubernetes::apply { 'datadog/daemonset.yaml':}
  profile::kubernetes::apply { 'datadog/deployment.yaml':}

  # As secret changes do not trigger pods update,
  # we must reload pods 'manually' to use the newly updated secret
  # If we delete a pod defined by daemonset,
  # this daemonset will recreate a new one
  profile::kubernetes::reload { 'datadog pods':
    app        => 'datadog',
    depends_on => [
      'datadog/secret.yaml',
      'datadog/daemonset.yaml',
    ]
  }
}
