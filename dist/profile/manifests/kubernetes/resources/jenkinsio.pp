# Deploy jenkinsio
#   Class: profile::kubernetes::resources::jenkinsio
#
#   This class deploy main jenkins website on Kubernetes
#
#   Parameters:
#     $clusters:
#       clusters contains a list of cluster information.
#
#     $image_tag:
#       Define tag used for nginx docker image
#
#     $storage_account_name:
#       Define storage account key to access nginx-cache storage account
#
#     $storage_account_key:
#       Define storage account key to access nginx-cache storage account
#
#     $url:
#       Define url endpoint to access jenkinsio
#
#     $aliases:
#       Define url endpoint aliases
#

class profile::kubernetes::resources::jenkinsio (
  Array  $aliases = [
    'jenkins.io',
    'jenkins-ci.org',
    'www.jenkins-ci.org'
    ],
  Array $clusters = $profile::kubernetes::params::clusters,
  String $image_tag = 'latest',
  String $storage_account_name = '',
  String $storage_account_key = '',
  String $url = 'www.jenkins.io'
) inherits profile::kubernetes::params {

  include ::stdlib
  require profile::kubernetes::kubectl

  $base64_storage_account_name = base64('encode', $storage_account_name, 'strict')
  $base64_storage_account_key = base64('encode', $storage_account_key, 'strict')

  $clusters.each | $cluster | {
    $context = $cluster['clustername']

    file { "${profile::kubernetes::params::resources}/${context}/jenkinsio":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    profile::kubernetes::apply{ "jenkinsio/secret.yaml on ${context}":
      context    => $context,
      parameters => {
        'storage_account_name' => $base64_storage_account_name,
        'storage_account_key'  => $base64_storage_account_key
      },
      resource   => 'jenkinsio/secret.yaml'
    }
    profile::kubernetes::apply{ "jenkinsio/service.yaml on ${context}":
      context  => $context,
      resource => 'jenkinsio/service.yaml'
    }

    profile::kubernetes::apply{ "jenkinsio/zh-service.yaml on ${context}":
      context  => $context,
      resource => 'jenkinsio/zh-service.yaml'
    }


    profile::kubernetes::apply{ "jenkinsio/ingress-tls.yaml on ${context}":
      context    => $context,
      parameters => {
        'url'     => $url,
        'aliases' => $aliases
      },
      resource   => 'jenkinsio/ingress-tls.yaml'
    }

    profile::kubernetes::apply{ "jenkinsio/configmap.yaml on ${context}":
      context  => $context,
      resource => 'jenkinsio/configmap.yaml'
    }

    profile::kubernetes::apply{ "jenkinsio/deployment.yaml on ${context}":
      context    => $context,
      parameters => {
        'image_tag' => $image_tag
      },
      resource   => 'jenkinsio/deployment.yaml'
    }

    profile::kubernetes::apply{ "jenkinsio/zh-configmap.yaml on ${context}":
      context  => $context,
      resource => 'jenkinsio/zh-configmap.yaml'
    }

    profile::kubernetes::apply{ "jenkinsio/zh-deployment.yaml on ${context}":
      context    => $context,
      parameters => {
        'image_tag' => $image_tag
      },
      resource   => 'jenkinsio/zh-deployment.yaml'
    }

    # As secret changes do not trigger pods update,
    # we must reload pods 'manually' to use the newly updated secret
    profile::kubernetes::reload { "jenkinsio pods on ${context}":
      context    => $context,
      app        => 'jenkinsio',
      depends_on => [
        'jenkinsio/secret.yaml',
        'jenkinsio/configmap.yaml',
      ]
    }

    profile::kubernetes::reload { "zhjenkinsio pods on ${context}":
      context    => $context,
      app        => 'zhjenkinsio',
      depends_on => [
        'jenkinsio/secret.yaml',
        'jenkinsio/zh-configmap.yaml',
      ]
    }

    profile::kubernetes::backup { "jenkinsio-tls on ${context}":
      context  => $context,
      resource => 'jenkinsio-tls'
    }

    # Can be remove once resources are removed from the cluster
    profile::kubernetes::delete{ "jenkinsio/cn-service.yaml on ${context}":
      context  => $context,
      resource => 'jenkinsio/cn-service.yaml'
    }

    profile::kubernetes::delete{ "jenkinsio/cn-configmap.yaml on ${context}":
      context  => $context,
      resource => 'jenkinsio/cn-configmap.yaml'
    }

    profile::kubernetes::delete{ "jenkinsio/cn-deployment.yaml on ${context}":
      context    => $context,
      parameters => {
        'image_tag' => $image_tag
      },
      resource   => 'jenkinsio/cn-deployment.yaml'
    }


  }
}
