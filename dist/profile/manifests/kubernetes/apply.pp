#   Define: profile::kubernetes::apply
#
#   This definition will template and apply kubernetes resource received by argument
#
#   Parameters:
#     $resource:
#       Resource name with following format <name>/file.yaml
#       ! ${module_name}/kubernetes/resources/${resource}.erb must exist
#
#     $kubeconfig:
#        Kubernetes kubeconfig file path
#
#     $parameters:
#       Parameters used in erb templates
#
#     $context:
#       The name of the kubeconfig context to use
#
#   Sample usage:
#     profile::kubernetes::apply { 'datadog/secret.yaml':
#       context =>  'default'
#       parameters => {
#         apiKey => 'secret_key'
#       }
#     }
#
define profile::kubernetes::apply (
  String $context = '',
  String $kubeconfig = $profile::kubernetes::params::kubeconfig,
  String $resource = $title,
  String $user = $profile::kubernetes::params::user,
  Hash $parameters = {}
) {

  include ::stdlib
  include profile::kubernetes::params

  if $context == '' {
    fail("Kubernetes context is required for resource ${title}")
  }

  $dirname = dirname($resource)
  $basename = basename($resource)

  file { "${profile::kubernetes::params::resources}/${context}/${resource}":
    ensure  => 'present',
    content => template("${module_name}/kubernetes/resources/${resource}.erb"),
    owner   => $profile::kubernetes::params::user,
  }

  $kubectl_options = "--context ${context} -f ${profile::kubernetes::params::resources}/${context}/${resource}"

  exec { "update ${resource} on ${context}":
    command     => "kubectl apply ${kubectl_options}",
    environment => ["KUBECONFIG=${kubeconfig}"] ,
    path        => [$profile::kubernetes::params::bin,$::path],
    refreshonly => true,
    logoutput   => true,
    subscribe   => File["${profile::kubernetes::params::resources}/${context}/${resource}"],
    user        => $user
  }

  # Remove resource from trash directory
  file { "${profile::kubernetes::params::trash}/${context}.${dirname}.${basename}":
    ensure  => 'absent'
  }
}
