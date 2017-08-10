#   Define: profile::kubernetes::reload
#
#   This definition will reload kubernetes resource received by argument
#
#   Parameters:
#     $resource:
#       Resource name with following format <name>/file.yaml
#       ! ${module_name}/kubernetes/resources/${resource}.erb must exist
#     $app:
#       Value for pods label 'app'
#     $depends_on:
#
#   Sample usage:
#     profile::kubernetes::reload { 'datadog':
#       app         => 'datadog',
#       depends_on  => [
#         "datadog/secret.yaml",
#         "datadog/daemonset.yaml"
#       ]
#     }
#
define profile::kubernetes::reload (
  String $resource = $title,
  String $app= undef,
  Array  $depends_on = undef
){
  include ::stdlib
  include profile::kubernetes::params

  $profile::kubernetes::params::clusters.each | $cluster | {
    $subscribe = $depends_on.map | $item | { Resource[Exec,"update ${item} on ${cluster[clustername]}"] }
    exec { "reload ${app} pods on ${cluster[clustername]}":
      command     => "kubectl delete pods -l app=${app}",
      path        => [$profile::kubernetes::params::bin],
      environment => ["KUBECONFIG=${profile::kubernetes::params::home}/.kube/${cluster[clustername]}.conf"] ,
      logoutput   => true,
      subscribe   => $subscribe,
      refreshonly => true
    }
  }
}
