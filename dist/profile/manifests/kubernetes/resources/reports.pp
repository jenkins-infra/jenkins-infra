# Deploy reports
#   Class: profile::kubernetes::resources::reports
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
#       Define url endpoint to access reports
#
#     $aliases:
#       Define url endpoint aliases
#

class profile::kubernetes::resources::reports (
  Array  $aliases = [
    'reports.jenkins-ci.org',
    ],
  Array $clusters = $profile::kubernetes::params::clusters,
  String $image_tag = 'alpine',
  String $storage_account_name = '',
  String $storage_account_key = '',
  String $url = 'reports.jenkins.io'
) inherits profile::kubernetes::params {

  include ::stdlib
  require profile::kubernetes::kubectl

  $base64_storage_account_name = base64('encode', $storage_account_name, 'strict')
  $base64_storage_account_key = base64('encode', $storage_account_key, 'strict')

  $clusters.each | $cluster | {
    $context = $cluster['clustername']

    file { "${profile::kubernetes::params::resources}/${context}/reports":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    profile::kubernetes::apply{ "reports/secret.yaml on ${context}":
      context    => $context,
      parameters => {
        'storage_account_name' => $base64_storage_account_name,
        'storage_account_key'  => $base64_storage_account_key
      },
      resource   => 'reports/secret.yaml'
    }
    profile::kubernetes::apply{ "reports/service.yaml on ${context}":
      context  => $context,
      resource => 'reports/service.yaml'
    }

    profile::kubernetes::apply{ "reports/ingress-tls.yaml on ${context}":
      context    => $context,
      parameters => {
        'url'     => $url,
        'aliases' => $aliases
      },
      resource   => 'reports/ingress-tls.yaml'
    }

    profile::kubernetes::apply{ "reports/deployment.yaml on ${context}":
      context    => $context,
      parameters => {
        'image_tag' => $image_tag
      },
      resource   => 'reports/deployment.yaml'
    }

    # As secret changes do not trigger pods update,
    # we must reload pods 'manually' to use the newly updated secret
    profile::kubernetes::reload { "reports pods on ${context}":
      context    => $context,
      app        => 'reports',
      depends_on => [
        'reports/secret.yaml',
      ]
    }

    profile::kubernetes::backup { "reports-tls on ${context}":
      context  => $context,
      resource => 'reports-tls'
    }
  }
}
