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
  String $context = '',
  String $resource = $title,
  String $user = $profile::kubernetes::params::user,
  String $kubeconfig = $profile::kubernetes::params::kubeconfig,
){
  include ::stdlib
  include profile::kubernetes::params

  $dirname = dirname($resource)
  $basename = basename($resource)

  # Add resource file to trash directory
  file { "${profile::kubernetes::params::trash}/${context}.${dirname}.${basename}":
    ensure  => 'present',
    content => template("${module_name}/kubernetes/resources/${resource}.erb"),
    owner   => $profile::kubernetes::params::user
  }

$delete_args = "\
--context ${context} \
--grace-period=60 \
--ignore-not-found=true \
-f ${profile::kubernetes::params::trash}/${context}.${dirname}.${basename}"

$apply_args = "\
--context ${context} \
--dry-run \
-f ${profile::kubernetes::params::resources}/${context}/${dirname}.${basename}"

  # Only run kubectl delete if the resources is deployed.
  exec { "Remove ${resource} on ${context}":
    command     => "kubectl delete ${delete_args}",
    environment => ["KUBECONFIG=${kubeconfig}"] ,
    path        => [$profile::kubernetes::params::bin,$::path],
    onlyif      => "test \"$(kubectl apply ${apply_args} | grep configured)\"",
    user        => $user,
  }

  # Remove resource file 
  file { "${profile::kubernetes::params::resources}/${context}/${resource}":
    ensure      => 'absent'
  }
}
