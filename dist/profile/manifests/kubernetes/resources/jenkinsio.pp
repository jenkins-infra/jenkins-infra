# Deploy jenkinsio
#   Class: profile::kubernetes::resources::jenkinsio
#
#   This class deploy main jenkins website on Kubernetes
#
#   Parameters:
#     $image_tag:
#       Define tag used for nginx docker image
#     $storage_account_name:
#       Define storage account key to access nginx-cache storage account
#     $storage_account_key:
#       Define storage account key to access nginx-cache storage account
#     $url:
#       Define url endpoint to access jenkinsio
#     $aliases:
#       Define url endpoint aliases
#

class profile::kubernetes::resources::jenkinsio (
  String $image_tag = 'alpine',
  String $storage_account_name = '',
  String $storage_account_key = '',
  String $url = 'www.jenkins.io',
  Array  $aliases = [
    'jenkins.io',
    'jenkins-ci.org',
    'www.jenkins-ci.org'
    ]
){

  include ::stdlib
  include profile::kubernetes::params
  include profile::kubernetes::kubectl

  $base64_storage_account_name = base64('encode', $storage_account_name, 'strict')
  $base64_storage_account_key = base64('encode', $storage_account_key, 'strict')

  file { "${profile::kubernetes::params::resources}/jenkinsio":
    ensure => 'directory',
    owner  => $profile::kubernetes::params::user,
  }

  profile::kubernetes::apply{ 'jenkinsio/secret.yaml':
    parameters => {
      'storage_account_name' => $base64_storage_account_name,
      'storage_account_key'  => $base64_storage_account_key
    }
  }
  profile::kubernetes::apply{ 'jenkinsio/service.yaml':
  }
  profile::kubernetes::apply{ 'jenkinsio/ingress-tls.yaml':
    parameters => {
      'url'     => $url,
      'aliases' => $aliases
    }
  }
  profile::kubernetes::apply{ 'jenkinsio/deployment.yaml':
    parameters => {
      'image_tag' => $image_tag
    }
  }

  # As secret changes do not trigger pods update,
  # we must reload pods 'manually' to use the newly updated secret
  profile::kubernetes::reload { 'jenkinsio pods':
    app        => 'jenkinsio',
    depends_on => [
      'jenkinsio/secret.yaml',
    ]
  }

  profile::kubernetes::backup { 'jenkinsio-tls':
  }

}
