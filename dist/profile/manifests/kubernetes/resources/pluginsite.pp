#   Class: profile::kubernetes::resources::pluginsite
#
#   This class deploy plugins jenkins website
#
#   Parameters:
#     $data_file_url:
#       Set endpoint for plugins data file
#     $url:
#       Set frontend url
#     $image_tag:
#       Set plugin-site image tag
#
#   Remark:
#     `kubectl get service nginx --namespace nginx-ingress` return service public ip
#     This public ip should be used for DNS record frontend_url -> this IP
#     In order to create letsencrypt certificates

# Deploy pluginsite resources on kubernetes cluster
class profile::kubernetes::resources::pluginsite (
    String $url = 'plugins.jenkins.io',
    String $data_file_url = 'https://ci.jenkins.io/job/Infra/job/plugin-site-api/job/generate-data/lastSuccessfulBuild/artifact/plugins.json.gzip',
    String $image_tag = ''
  ){
  include profile::kubernetes::params
  require profile::kubernetes::kubectl
  require profile::kubernetes::resources::nginx
  require profile::kubernetes::resources::lego

  file { "${profile::kubernetes::params::resources}/pluginsite":
    ensure => 'directory',
    owner  => $profile::kubernetes::params::user,
  }

  profile::kubernetes::apply { 'pluginsite/ingress-tls.yaml':
    parameters  => {
      'url'     => $url,
    }
  }
  profile::kubernetes::apply { 'pluginsite/configmap.yaml':
    parameters  => {
      'url'           => "https://${url}/api",
      'data_file_url' => $data_file_url
    }
  }
  profile::kubernetes::apply { 'pluginsite/service.yaml':}

  profile::kubernetes::apply { 'pluginsite/deployment.yaml':
    parameters => {
      'image_tag' => $image_tag
    }
  }

  # As configmap changes do not trigger pods update,
  # we must reload pods 'manually' to use the newly updated configmap
  exec { 'Reload pluginsite pods':
    path        => ["${profile::kubernetes::params::bin}/"],
    command     => 'kubectl delete pods -l app=plugins-jenkins',
    refreshonly => true,
    environment => ["KUBECONFIG=${profile::kubernetes::params::home}/.kube/config"] ,
    logoutput   => true,
    subscribe   => Exec['apply pluginsite/configmap.yaml']
  }
}
