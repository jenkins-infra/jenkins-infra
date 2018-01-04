#   Class: profile::kubernetes::resources::nginx
#
#   This class deploy an nginx ingress resources
#   from gce
#
# Deploy nginx-ingress resources on kubernetes cluster
# -> https://github.com/kubernetes/ingress/blob/master/controllers/nginx/Changelog.md
#
class profile::kubernetes::resources::nginx (
    Array $clusters = $profile::kubernetes::params::clusters
  ) inherits profile::kubernetes::params{

  require profile::kubernetes::kubectl

  $clusters.each | $cluster | {
    $context = $cluster['clustername']

    # Only set field loadBalancerIp if a publicIp is provided
    if has_key($cluster,'nginx_public_ip'){
      $public_ip = $cluster['nginx_public_ip']
    }
    else{
      $public_ip = 'none'
    }

    file { "${profile::kubernetes::params::resources}/${context}/nginx":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    profile::kubernetes::apply { "nginx/namespace.yaml on ${context}":
      context  => $context,
      resource => 'nginx/namespace.yaml'
    }
    profile::kubernetes::apply { "nginx/configmap.yaml on ${context}":
      context  => $context,
      resource => 'nginx/configmap.yaml'
    }
    profile::kubernetes::apply { "nginx/default-deployment.yaml on ${context}":
      context  => $context,
      resource => 'nginx/default-deployment.yaml'
    }
    profile::kubernetes::apply { "nginx/default-service.yaml on ${context}":
      context  => $context,
      resource => 'nginx/default-service.yaml'
    }
    profile::kubernetes::apply { "nginx/deployment.yaml on ${context}":
      context  => $context,
      resource => 'nginx/deployment.yaml'
    }
    profile::kubernetes::apply { "nginx/service.yaml on ${context}":
      context    => $context,
      resource   => 'nginx/service.yaml',
      parameters =>  {
        'loadBalancerIp' => $public_ip
      }
    }

    # As configmap changes do not trigger pods update,
    # we must reload pods 'manually' to use the newly updated secret
    profile::kubernetes::reload { "nginx pods on ${context}":
      context    => $context,
      app        => 'nginx',
      depends_on => [
        'nginx/configmap.yaml'
      ]
    }
  }
}
