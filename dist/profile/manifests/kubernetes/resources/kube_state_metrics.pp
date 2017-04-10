#   Class: profile::kubernetes::resources::kube_state_metrics 
#
#   This class deploy a kube-state-metrics container on kubernetes  cluster.
#   kube-state-metrics is a simple service that listens to the Kubernetes API server and generates metrics about the state of the objects
#    -> https://github.com/kubernetes/kube-state-metrics
#
#   Parameters:
#     $image_tag:
#       Set kube-state-metric image tag

class profile::kubernetes::resources::kube_state_metrics(
  String $image_tag = 'v0.4.1'
){
  include profile::kubernetes::params
  include profile::kubernetes::kubectl

  file { "${profile::kubernetes::params::resources}/kube_state_metrics":
    ensure => 'directory',
    owner  => $profile::kubernetes::params::user,
  }

  profile::kubernetes::apply{ 'kube_state_metrics/service.yaml':}
  profile::kubernetes::apply{ 'kube_state_metrics/deployment.yaml':
    parameters => {
      'image_tag' => $image_tag
    }
  }
}
