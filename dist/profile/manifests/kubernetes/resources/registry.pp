#   Class: profile::kubernetes::registry
#
#   This class apply docker registry configuration
#   to authenticate with private docker registry
#
#   Parameters:
#     $clusters:
#       clusters contains a list of cluster information.
#
#     $dockerconfigjson:
#       This string contain non base64 docker registry configuration in json
#       -> https://kubernetes.io/docs/user-guide/images/#creating-a-secret-with-a-docker-config
#
class profile::kubernetes::resources::registry (
    Array $clusters = $profile::kubernetes::params::clusters,
    String $dockerconfigjson = '{"auths": {"https://index.docker.io/v1/": {"auth": "base64_auth"}}}'
  ) inherits profile::kubernetes::params {

  include ::stdlib
  require profile::kubernetes::kubectl

  $clusters.each | $cluster | {
    $context = $cluster['clustername']

    file { "${profile::kubernetes::params::resources}/${context}/registry":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    profile::kubernetes::apply { "registry/secret.yaml on ${context}":
      context    => $context,
      parameters => {
          'dockerconfigjson' => base64('encode', $dockerconfigjson, 'strict')
      },
      resource   => 'registry/secret.yaml'
    }
  }
}
