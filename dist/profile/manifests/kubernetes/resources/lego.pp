#   Class: profile::kubernetes::resources::lego
#
#   This class install kube lego
#   => https://github.com/jetstack/kube-lego
#
#   Parameters:
#     $email:
#       Mail address used by letsencrypt to send notifications
#     $url:
#       Endpoint used by letsencrypt to get certificate
#       This value can also be set to https://acme-staging.api.letsencrypt.org/directory
#       for staging environment
#
#
class profile::kubernetes::resources::lego (
    String $email = 'infra@lists.jenkins-ci.org',
    String $url = 'https://acme-v01.api.letsencrypt.org/directory',
    Array $clusters = $profile::kubernetes::params::clusters
  ) inherits profile::kubernetes::params{

  require profile::kubernetes::kubectl

  $clusters.each | $cluster | {
    $context = $cluster['clustername']

    file { "${profile::kubernetes::params::resources}/${context}/lego":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    profile::kubernetes::apply { "lego/namespace.yaml on ${context}":
      context  => $context,
      resource => 'lego/namespace.yaml'
    }

    profile::kubernetes::apply { "lego/configmap.yaml on ${context}":
      context    => $context,
      parameters => {
        'email' => $email,
        'url'   => $url
      },
      resource   => 'lego/configmap.yaml'
    }

    profile::kubernetes::apply { "lego/deployment.yaml on ${context}":
      context  => $context,
      resource => 'lego/deployment.yaml'
    }

    # As configmap changes do not trigger pods update,
    # we must reload pods 'manually' to use the newly updated configmap
    profile::kubernetes::reload { "kube-lego pods on ${context}":
      context    => $context,
      app        => 'kube-lego',
      depends_on => [
        'lego/configmap.yaml'
      ]
    }
  }
}
