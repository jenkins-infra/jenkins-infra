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
    String $url = 'https://acme-v01.api.letsencrypt.org/directory'
  ){
  include profile::kubernetes::params
  require profile::kubernetes::kubectl

  file { "${profile::kubernetes::params::resources}/lego":
    ensure => 'directory',
    owner  => $profile::kubernetes::params::user,
  }

  profile::kubernetes::apply { 'lego/namespace.yaml':}

  profile::kubernetes::apply { 'lego/configmap.yaml':
    parameters => {
      'email' => $email,
      'url'   => $url
    }
  }

  profile::kubernetes::apply { 'lego/deployment.yaml':}

  # As configmap changes do not trigger pods update,
  # we must reload pods 'manually' to use the newly updated configmap
  exec { 'Reload lego pods':
    path        => ["${profile::kubernetes::params::bin}/"],
    command     => 'kubectl delete pods -l app=kube-lego',
    refreshonly => true,
    environment => ["KUBECONFIG=${profile::kubernetes::params::home}/.kube/config"] ,
    logoutput   => true,
    subscribe   => Exec['apply lego/configmap.yaml']
  }
}
