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
  String $image_tag = ''
){

  include ::stdlib
  include profile::kubernetes::params
  include profile::kubernetes::kubectl
  include profile::kubernetes::resources::azurelogs

  file { "${profile::kubernetes::params::resources}/fluentd":
    ensure => 'directory',
    owner  => $profile::kubernetes::params::user,
  }

  profile::kubernetes::apply{ 'fluentd/daemonset.yaml':
    parameters => {
      'image_tag'      => $image_tag,
      'deploy_context' => $profile::kubernetes::params::deploy_context,
    }
  }

  # As secret changes do not trigger pods update,
  # we must reload pods 'manually' to use the newly updated secret
  # If we delete a pod defined by daemonset,
  # this daemonset will recreate a new one
  profile::kubernetes::reload { 'fluentd pods':
    app        => 'fluentd',
    depends_on => [
      'azurelogs/secret.yaml',
      'fluentd/daemonset.yaml',
    ]
  }

}
