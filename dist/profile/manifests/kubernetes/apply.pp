#   Define: profile::kubernetes::apply
#
#   This definition will template and apply kubernetes resource received by argument
#
#   Parameters:
#     $resource:
#       Resource name with following format <name>/file.yaml
#       ! ${module_name}/kubernetes/resources/${resource}.erb must exist
#     $parameters:
#       Parameters used in erb templates
#
#   Sample usage:
#     profile::kubernetes::apply { 'datadog/secret.yaml':
#       parameters => {
#         apiKey => 'secret_key'
#       }
#     }
#
define profile::kubernetes::apply (
  String $resource = $title,
  Hash $parameters = {},
){
  include ::stdlib
  include profile::kubernetes::params

  $clusters = $profile::kubernetes::params::clusters

  file { "${profile::kubernetes::params::resources}/${resource}":
    ensure  => 'present',
    content => template("${module_name}/kubernetes/resources/${resource}.erb"),
    owner   => $profile::kubernetes::params::user,
  }

  $clusters.each | $cluster | {
    # --dry-run doesn't know if a resource needs to be updated (only created or not) therefor we trigger an update
    # only if the configuration file is updated by puppet run
    exec { "update ${resource} on ${cluster[clustername]}":
      command     => "kubectl apply -f ${profile::kubernetes::params::resources}/${resource}",
      path        => [$profile::kubernetes::params::bin,$path],
      environment => ["KUBECONFIG=${profile::kubernetes::params::home}/.kube/${cluster[clustername]}.conf"] ,
      refreshonly => true,
      logoutput   => true,
      subscribe   => File["${profile::kubernetes::params::resources}/${resource}"],
      onlyif      => "test \"$(kubectl apply --dry-run -f ${profile::kubernetes::params::resources}/${resource} | grep configured)\""
    }

    # Always deploys a resource that is not yet created on the cluster
    exec { "init ${resource} on ${cluster[clustername]}":
      command     => "kubectl apply -f ${profile::kubernetes::params::resources}/${resource}",
      path        => [$profile::kubernetes::params::bin,$path],
      environment => ["KUBECONFIG=${profile::kubernetes::params::home}/.kube/${cluster[clustername]}.conf"] ,
      logoutput   => true,
      onlyif      => "test \"$(kubectl apply --dry-run -f ${profile::kubernetes::params::resources}/${resource} | grep created)\""
    }
  }

  # Remove resource from trash directory
  file { "${profile::kubernetes::params::trash}/${resource}":
    ensure  => 'absent'
  }
}
