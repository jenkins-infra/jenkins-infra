# Deploy fluentd
#   Class: profile::kubernetes::resources::azurelogs
#
#   This class ensure that one fluentd pod run on each node
#   olblak/fluentd-k8s-azure is used to fetch logs from kubernetes\
#   and send them on loganalytics/blob storage
#
#   Parameters:
#     $image_tag:
#       Define tag used for olblak/fluentd-k8s-azure
#

class profile::kubernetes::resources::fluentd (
  String $image_tag = '',
  Array $clusters = $profile::kubernetes::params::clusters
) inherits profile::kubernetes::params {

  include ::stdlib
  require profile::kubernetes::kubectl
  require profile::kubernetes::resources::azurelogs

  $clusters.each | $cluster | {
    $context = $cluster['clustername']

    file { "${profile::kubernetes::params::resources}/${context}/fluentd":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    profile::kubernetes::apply{ "fluentd/daemonset.yaml on ${context}":
      context    => $context,
      parameters => {
        'image_tag' => $image_tag
      },
      resource   =>  'fluentd/daemonset.yaml'
    }

    # As secret changes do not trigger pods update,
    # we must reload pods 'manually' to use the newly updated secret
    # If we delete a pod defined by daemonset,
    # this daemonset will recreate a new one
    profile::kubernetes::reload { "fluentd pods on ${context}":
      context    => $context,
      app        => 'fluentd',
      depends_on => [
        'azurelogs/secret.yaml',
        'fluentd/daemonset.yaml',
      ]
    }
  }
}
