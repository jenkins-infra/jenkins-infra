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
    Array $aliases = [],
    Array $clusters = $profile::kubernetes::params::clusters
  ) inherits profile::kubernetes::params {

  require profile::kubernetes::kubectl
  require profile::kubernetes::resources::nginx
  require profile::kubernetes::resources::lego

  $clusters.each | $cluster | {
    $context = $cluster['clustername']

    file { "${profile::kubernetes::params::resources}/${context}/pluginsite":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    profile::kubernetes::apply { "pluginsite/ingress-tls.yaml on ${context}":
      context    => $context,
      parameters => {
        'url'     => $url,
        'aliases' => $aliases
      },
      resource   => 'pluginsite/ingress-tls.yaml'
    }
    profile::kubernetes::apply { "pluginsite/configmap.yaml on ${context}":
      context    => $context,
      parameters => {
        'url'           => "https://${url}/api",
        'data_file_url' => $data_file_url
      },
      resource   => 'pluginsite/configmap.yaml'
    }
    profile::kubernetes::apply { "pluginsite/service.yaml on ${context}":
      context  => $context,
      resource => 'pluginsite/service.yaml'
    }

    profile::kubernetes::apply { "pluginsite/deployment.yaml on ${context}":
      context    => $context,
      parameters => {
        'image_tag' => $image_tag
      },
      resource   => 'pluginsite/deployment.yaml'
    }

    # As configmap changes do not trigger pods update,
    # we must reload pods 'manually' to use the newly updated configmap
    profile::kubernetes::reload { "pluginsite pods on ${context}":
      context    => $context,
      app        => 'plugins-jenkins',
      depends_on => [
        'pluginsite/configmap.yaml',
      ]
    }

    profile::kubernetes::backup { "pluginsite-tls on ${context}":
      context  => $context,
      resource => 'pluginsite-tls'
    }
  }
}
