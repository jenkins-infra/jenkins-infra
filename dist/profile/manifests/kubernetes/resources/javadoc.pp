# Deploy javadoc
#   Class: profile::kubernetes::resources::javadoc
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
#       Define url endpoint to access javadoc
#
#     $aliases:
#       Define url endpoint aliases
#

class profile::kubernetes::resources::javadoc (
  Array  $aliases = [
    'javadoc.jenkins-ci.org',
    ],
  Array $clusters = $profile::kubernetes::params::clusters,
  String $image_tag = 'alpine',
  String $storage_account_name = '',
  String $storage_account_key = '',
  String $url = 'javadoc.jenkins.io'
) inherits profile::kubernetes::params {

  include ::stdlib
  require profile::kubernetes::kubectl

  $base64_storage_account_name = base64('encode', $storage_account_name, 'strict')
  $base64_storage_account_key = base64('encode', $storage_account_key, 'strict')

  $clusters.each | $cluster | {
    $context = $cluster['clustername']

    file { "${profile::kubernetes::params::resources}/${context}/javadoc":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    profile::kubernetes::apply{ "javadoc/secret.yaml on ${context}":
      context    => $context,
      parameters => {
        'storage_account_name' => $base64_storage_account_name,
        'storage_account_key'  => $base64_storage_account_key
      },
      resource   => 'javadoc/secret.yaml'
    }

    profile::kubernetes::apply{ "javadoc/configmap.yaml on ${context}":
      context  => $context,
      resource => 'javadoc/configmap.yaml'
    }

    profile::kubernetes::apply{ "javadoc/service.yaml on ${context}":
      context  => $context,
      resource => 'javadoc/service.yaml'
    }

    profile::kubernetes::apply{ "javadoc/ingress-tls.yaml on ${context}":
      context    => $context,
      parameters => {
        'url'     => $url,
        'aliases' => $aliases
      },
      resource   => 'javadoc/ingress-tls.yaml'
    }

    profile::kubernetes::apply{ "javadoc/deployment.yaml on ${context}":
      context    => $context,
      parameters => {
        'image_tag' => $image_tag
      },
      resource   => 'javadoc/deployment.yaml'
    }

    # As secret changes do not trigger pods update,
    # we must reload pods 'manually' to use the newly updated secret
    profile::kubernetes::reload { "javadoc pods on ${context}":
      context    => $context,
      app        => 'javadoc',
      depends_on => [
        'javadoc/secret.yaml',
        'javadoc/configmap.yaml'
      ]
    }

    profile::kubernetes::backup { "javadoc-tls on ${context}":
      context  => $context,
      resource => 'javadoc-tls'
    }
  }
}
