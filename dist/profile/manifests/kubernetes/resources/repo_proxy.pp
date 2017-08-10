# Deploy repo_proxy
#   Class: profile::kubernetes::resources::repo_proxy
#
#   This class deploy a proxy cache in front of repo.jenkins-ci.org
#
#   Parameters:
#     $image_tag:
#       Define tag used for jenkinsciinfra/repo_proxy
#     $storage_account_name:
#       Define storage account key to access nginx-cache storage account
#     $storage_account_key:
#       Define storage account key to access nginx-cache storage account
#     $url:
#       Define url endpoint to access repo_proxy
#     $aliases:
#       Define url endpoint aliases
#

class profile::kubernetes::resources::repo_proxy (
  String $image_tag = '',
  String $storage_account_name = '',
  String $storage_account_key = '',
  String $url = '',
  Array  $aliases = []
){

  include ::stdlib
  include profile::kubernetes::params
  include profile::kubernetes::kubectl

  $base64_storage_account_name = base64('encode', $storage_account_name, 'strict')
  $base64_storage_account_key = base64('encode', $storage_account_key, 'strict')

  file { "${profile::kubernetes::params::resources}/repo_proxy":
    ensure => 'directory',
    owner  => $profile::kubernetes::params::user,
  }

  profile::kubernetes::apply{ 'repo_proxy/secret.yaml':
    parameters => {
      'storage_account_name' => $base64_storage_account_name,
      'storage_account_key'  => $base64_storage_account_key
    }
  }
  profile::kubernetes::apply{ 'repo_proxy/service.yaml':
  }
  profile::kubernetes::apply{ 'repo_proxy/ingress-tls.yaml':
    parameters => {
      'url'     => $url,
      'aliases' => $aliases
    }
  }
  profile::kubernetes::apply{ 'repo_proxy/deployment.yaml':
    parameters => {
      'image_tag' => $image_tag
    }
  }

  # As secret changes do not trigger pods update,
  # we must reload pods 'manually' to use the newly updated secret
  profile::kubernetes::reload { 'repo_proxy pods':
    app        => 'repo-proxy',
    depends_on => [
      'repo_proxy/secret.yaml',
    ]
  }

}
