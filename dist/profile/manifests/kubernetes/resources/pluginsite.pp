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
#     $aliases:
#       Set a list of $url aliases used by ingress
#
#   Remark:
#     `kubectl get service nginx --namespace nginx-ingress` return service public ip
#     This public ip should be used for DNS record frontend_url -> this IP
#     In order to create letsencrypt certificates

# Deploy pluginsite resources on kubernetes cluster
class profile::kubernetes::resources::pluginsite (
    String $url = '',
    String $data_file_url = 'https://ci.jenkins.io/job/Infra/job/plugin-site-api/job/generate-data/lastSuccessfulBuild/artifact/plugins.json.gzip',
    String $image_tag = '',
    Array $aliases = []
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
      'aliases' => $aliases
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
  profile::kubernetes::reload { 'pluginsite pods':
    app        => 'plugins-jenkins',
    depends_on => [
      'pluginsite/configmap.yaml',
    ]
  }

}
