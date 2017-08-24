#   Class: profile::kubernetes::resources::nginx
#
#   This class deploy an nginx ingress resources
#   from gce
#
# Deploy nginx-ingress resources on kubernetes cluster
# -> https://github.com/kubernetes/ingress/blob/master/controllers/nginx/Changelog.md
#
class profile::kubernetes::resources::nginx (
  ){
  include profile::kubernetes::params
  require profile::kubernetes::kubectl

  file { "${profile::kubernetes::params::resources}/nginx":
    ensure => 'directory',
    owner  => $profile::kubernetes::params::user,
  }

  profile::kubernetes::apply { 'nginx/namespace.yaml':}
  profile::kubernetes::apply { 'nginx/configmap.yaml':}
  profile::kubernetes::apply { 'nginx/default-deployment.yaml':}
  profile::kubernetes::apply { 'nginx/default-service.yaml':}
  profile::kubernetes::apply { 'nginx/deployment.yaml':}
  profile::kubernetes::apply { 'nginx/service.yaml':}

  # As configmap changes do not trigger pods update,
  # we must reload pods 'manually' to use the newly updated secret
  profile::kubernetes::reload { 'nginx pods':
    app        => 'nginx',
    depends_on => [
      'nginx/configmap.yaml'
    ]
  }

}
