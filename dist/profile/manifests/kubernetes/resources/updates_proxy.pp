# Deploy updates_proxy
#   Class: profile::kubernetes::resources::updates_proxy
#
#   This class deploy a fallback update center.
#   This service only contains htaccess to redirect to repo.jenkins-ci.org
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
#       Define url endpoint to access updates_proxy
#
#     $aliases:
#       Define url endpoint aliases
#

class profile::kubernetes::resources::updates_proxy (
  Array  $aliases = [],
  Array $clusters = $profile::kubernetes::params::clusters,
  String $image_tag = '2.4.34',
  String $storage_account_name = '',
  String $storage_account_key = '',
  String $url = 'azure.updates.jenkins.io'
) inherits profile::kubernetes::params {

  include ::stdlib
  require profile::kubernetes::kubectl

  $base64_storage_account_name = base64('encode', $storage_account_name, 'strict')
  $base64_storage_account_key = base64('encode', $storage_account_key, 'strict')

  $clusters.each | $cluster | {
    $context = $cluster['clustername']

    file { "${profile::kubernetes::params::resources}/${context}/updates_proxy":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    profile::kubernetes::apply{ "updates_proxy/secret.yaml on ${context}":
      context    => $context,
      parameters => {
        'storage_account_name' => $base64_storage_account_name,
        'storage_account_key'  => $base64_storage_account_key
      },
      resource   => 'updates_proxy/secret.yaml'
    }

    profile::kubernetes::apply{ "updates_proxy/configmap.yaml on ${context}":
      context  => $context,
      resource => 'updates_proxy/configmap.yaml'
    }

    profile::kubernetes::apply{ "updates_proxy/service.yaml on ${context}":
      context  => $context,
      resource => 'updates_proxy/service.yaml'
    }

    profile::kubernetes::apply{ "updates_proxy/ingress-tls.yaml on ${context}":
      context    => $context,
      parameters => {
        'url'     => $url,
        'aliases' => $aliases
      },
      resource   => 'updates_proxy/ingress-tls.yaml'
    }

    profile::kubernetes::apply{ "updates_proxy/deployment.yaml on ${context}":
      context    => $context,
      parameters => {
        'image_tag' => $image_tag
      },
      resource   => 'updates_proxy/deployment.yaml'
    }

    # As secret changes do not trigger pods update,
    # we must reload pods 'manually' to use the newly updated secret
    profile::kubernetes::reload { "updates_proxy pods on ${context}":
      context    => $context,
      app        => 'updates_proxy',
      depends_on => [
        'updates_proxy/secret.yaml',
        'updates_proxy/configmap.yaml'
      ]
    }

    profile::kubernetes::backup { "updates_proxy-tls on ${context}":
      context  => $context,
      resource => 'updates_proxy-tls'
    }
  }
}
