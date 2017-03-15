# Define: profile::kubernetes::apply
#
# This definition will template and apply kubernetes resource received by argument
#
# Parameters:
#   $resource:
#     Resource name with following format <name>/file.yaml
#     ! ${module_name}/kubernetes/resources/${resource}.erb must exist
#   $parameters:
#     Parameters used in erb templates
#
# Sample usage:
#   profile::kubernetes::apply { 'datadog/secret.yaml':
#     parameters => {
#       apiKey => 'secret_key'
#     }
#   }
#
define profile::kubernetes::apply (
  String $resource = $title,
  Hash $parameters = {}
){
  include ::stdlib
  include profile::kubernetes::params

  file { "${profile::kubernetes::params::resources}/${resource}":
    ensure  => 'present',
    content => template("${module_name}/kubernetes/resources/${resource}.erb"),
    owner   => $profile::kubernetes::params::user,
  }

  exec { "apply ${resource}":
    command     => "kubectl apply -f ${profile::kubernetes::params::resources}/${resource}",
    path        => [$profile::kubernetes::params::bin],
    environment => ["KUBECONFIG=${profile::kubernetes::params::home}/.kube/config"] ,
    refreshonly => true,
    logoutput   => true,
    subscribe   => File["${profile::kubernetes::params::resources}/${resource}"],
  }
}
