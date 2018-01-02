#   Define: profile::kubernetes::reload
#
#   This definition will reload kubernetes resource received by argument
#
#   Parameters:
#     $app:
#       Value for pods label 'app'
#     $depends_on:
#       Define which resources need to be monitored in order to trigger this reload
#
#     $clusters:
#       List of cluster information, cfr profile::kubernetes::params for more
#       informations

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
  String $context = '',
  String $app= undef,
  String $user = $profile::kubernetes::params::user,
  String $kubeconfig = $profile::kubernetes::params::kubeconfig,
  Array  $depends_on = undef,
){
  include ::stdlib
  include profile::kubernetes::params

  $subscribe = $depends_on.map | $item | { Resource[Exec,"update ${item} on ${context}"] }

  exec { "reload ${app} pods on ${context}":
    command     => "kubectl delete pods --context ${context} -l app=${app}",
    path        => [$profile::kubernetes::params::bin,$::path],
    environment => ["KUBECONFIG=${kubeconfig}"] ,
    logoutput   => true,
    subscribe   => $subscribe,
    refreshonly => true,
    user        => $user
  }
}
