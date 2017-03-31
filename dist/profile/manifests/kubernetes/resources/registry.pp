#   Class: profile::kubernetes::registry
#
#   This class apply docker registry configuration
#   to authenticate with private docker registry
#
#   Parameters:
#     $dockerconfigjson:
#       This string contain non base64 docker registry configuration in json
#       -> https://kubernetes.io/docs/user-guide/images/#creating-a-secret-with-a-docker-config
#
class profile::kubernetes::resources::registry (
    String $dockerconfigjson = undef
  ){
  include ::stdlib
  include profile::kubernetes::params
  require profile::kubernetes::kubectl

  file { "${profile::kubernetes::params::resources}/registry":
    ensure => 'directory',
    owner  => $profile::kubernetes::params::user,
  }

  profile::kubernetes::apply { 'registry/secret.yaml':
    parameters => {
        'dockerconfigjson' => base64('encode', $dockerconfigjson, 'strict')
    },
  }
}
