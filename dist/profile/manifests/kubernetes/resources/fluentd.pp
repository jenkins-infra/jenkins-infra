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
      'image_tag' => $image_tag
    }
  }

  # As secret changes do not trigger pods update,
  # we must reload pods 'manually' to use the newly updated secret
  # If we delete a pod defined by daemonset,
  # this daemonset will recreate a new one
  # Daemonset still need to be reset
  exec { 'Reload fluentd pods':
    path        => ["${profile::kubernetes::params::bin}/"],
    command     => 'kubectl delete pods -l app=fluentd --grace-period=10',
    refreshonly => true,
    environment => ["KUBECONFIG=${profile::kubernetes::params::home}/.kube/config"] ,
    logoutput   => true,
    subscribe   => [
      Exec['apply azurelogs/secret.yaml'],
      Exec['apply fluentd/daemonset.yaml']
    ]
  }
}
