#   Define: profile::kubernetes::delete
#
#   This definition move resources to the trash directory 
#   then delete it from remote cluster.
#   We do not clean the trash directory.
#
#   This definition does exactly the opposite of profile::kubernetes::apply
#
#   Parameters:
#     $resource:
#       Resource name with following format <name>/file.yaml
#       ! ${module_name}/kubernetes/resources/${resource}.erb must exist
#     $clusters:
#       List of cluster information, cfr profile::kubernetes::params for more
#       informations
#
#   Sample usage:
#     profile::kubernetes::delete{ 'nginx/deployment.yaml':
#     }
#
define profile::kubernetes::delete (
  String $resource = $title,
  $clusters = $profile::kubernetes::params::clusters
){
  include ::stdlib
  include profile::kubernetes::params

  $dirname = dirname($resource)
  $basename = basename($resource)

  # Add resource file to trash directory
  file { "${profile::kubernetes::params::trash}/${dirname}.${basename}":
    ensure  => 'present',
    content => template("${module_name}/kubernetes/resources/${resource}.erb"),
    owner   => $profile::kubernetes::params::user
  }

  $clusters.each | $cluster | {
    # Only run kubectl delete if the resources is deployed.
    exec { "Remove ${resource} on ${cluster[clustername]}":
      command     => "kubectl delete --grace-period=60 --ignore-not-found=true -f ${profile::kubernetes::params::trash}/${dirname}.${basename}",
      path        => [$profile::kubernetes::params::bin,$::path],
      environment => ["KUBECONFIG=${profile::kubernetes::params::home}/.kube/${cluster[clustername]}.conf"] ,
      onlyif      => "test \"$(kubectl apply --dry-run=true -f ${profile::kubernetes::params::trash}/${dirname}.${basename} | grep configured)\""
    }
  }

  # Remove resource file 
  file { "${profile::kubernetes::params::resources}/${resource}":
    ensure      => 'absent'
  }
}
