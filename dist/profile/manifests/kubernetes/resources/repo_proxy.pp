# Deploy repo_proxy
#   Class: profile::kubernetes::resources::repo_proxy
#
#   This class deploy a proxy cache in front of repo.jenkins-ci.org
#
#   Parameters:
#     $clusters:
#       clusters contains a list of cluster information.
#
#     $aliases:
#       Define url endpoint aliases
#
#     $image_tag:
#       Define tag used for jenkinsciinfra/repo_proxy
#
#     $storage_account_name:
#       Define storage account key to access nginx-cache storage account
#
#     $storage_account_key:
#       Define storage account key to access nginx-cache storage account
#
#     $url:
#       Define url endpoint to access repo_proxy
#

class profile::kubernetes::resources::repo_proxy (
  Array  $aliases = [],
  Array $clusters = $profile::kubernetes::params::clusters,
  String $image_tag = '',
  String $bin = $profile::kubernetes::params::bin,
  String $storage_account_name = '',
  String $storage_account_key = '',
  String $url = '',
  String $user = $profile::kubernetes::params::user,
) inherits profile::kubernetes::params {

  include ::stdlib
  require profile::kubernetes::kubectl

  $base64_storage_account_name = base64('encode', $storage_account_name, 'strict')
  $base64_storage_account_key = base64('encode', $storage_account_key, 'strict')

  file { "${bin}/clean_repo_proxy_cache":
    ensure  => 'present',
    content => template("${module_name}/kubernetes/clean_repo_proxy_cache.erb"),
    owner   => $user,
    mode    => '0755'
  }

  $clusters.each | $cluster | {
    $context = $cluster['clustername']

    file { "${profile::kubernetes::params::resources}/${context}/repo_proxy":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    profile::kubernetes::apply{ "repo_proxy/secret.yaml on ${context}":
      context    => $context,
      parameters => {
        'storage_account_name' => $base64_storage_account_name,
        'storage_account_key'  => $base64_storage_account_key
      },
      resource   => 'repo_proxy/secret.yaml'
    }
    profile::kubernetes::apply{ "repo_proxy/service.yaml on ${context}":
      context  => $context,
      resource => 'repo_proxy/service.yaml'
    }

    profile::kubernetes::apply{ "repo_proxy/persistentVolume.yaml on ${context}" :
      context  => $context,
      resource => 'repo_proxy/persistentVolume.yaml'
    }

    profile::kubernetes::apply{ "repo_proxy/persistentVolumeClaim.yaml on ${context}":
      context  => $context,
      resource => 'repo_proxy/persistentVolumeClaim.yaml'
    }

    profile::kubernetes::apply{ "repo_proxy/ingress-tls.yaml on ${context}":
      context    => $context,
      parameters => {
        'url'     => $url,
        'aliases' => $aliases
      },
      resource   => 'repo_proxy/ingress-tls.yaml'
    }
    profile::kubernetes::apply{ "repo_proxy/deployment.yaml on ${context}":
      context    => $context,
      parameters => {
        'image_tag' => $image_tag
      },
      resource   => 'repo_proxy/deployment.yaml'
    }

    # As secret changes do not trigger pods update,
    # we must reload pods 'manually' to use the newly updated secret
    profile::kubernetes::reload { "repo_proxy pods on ${context}":
      context    => $context,
      app        => 'repo-proxy',
      depends_on => [
        'repo_proxy/secret.yaml',
      ]
    }

    profile::kubernetes::backup { "repo-proxy-tls on ${context}":
      context  => $context,
      resource => 'repo-proxy-tls'
    }
  }
}
