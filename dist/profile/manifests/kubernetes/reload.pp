#   Define: profile::kubernetes::reload
#
#   This definition will reload kubernetes resource received by argument
#
#   Parameters:
#     $app:
#       Value for pods label 'app'
#
#     $context:
#       The name of the kubeconfig context to use
#
#     $kubeconfig:
#        Kubernetes kubeconfig file path
#
#     $users:
#       System user who own Kubernetes project
#
#     $depends_on:
#       Define which resources need to be monitored in order to trigger this reload
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
  String $app= undef,
  String $context = '',
  String $home = $profile::kubernetes::params::home,
  String $kubeconfig = $profile::kubernetes::params::kubeconfig,
  String $user = $profile::kubernetes::params::user,
  String $namespace = 'default',
  Array  $depends_on = undef
){
  include ::stdlib
  include profile::kubernetes::params

  if $context == '' {
    fail("Kubernetes context is required for resource ${title}")
  }

  $subscribe = $depends_on.map | $item | { Resource[Exec,"update ${item} on ${context}"] }

  exec { "reload ${app} pods on ${context}":
    command     => "kubectl delete pods --namespace ${namespace} --context ${context} -l app=${app}",
    cwd         => $home,
    path        => [$profile::kubernetes::params::bin,$::path],
    environment => [
      "KUBECONFIG=${kubeconfig}",
      "HOME=${home}"
    ] ,
    logoutput   => true,
    subscribe   => $subscribe,
    refreshonly => true,
    user        => $user
  }
}
