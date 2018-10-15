#   Class: profile::kubernetes::resources::chatbot_jenkinsadmin
#
#   This class deploys the Jenkins Admin bot on IRC
#
#
class profile::kubernetes::resources::chatbot_jenkinsadmin (
    String $github_login,
    String $github_password,
    String $jira_login,
    String $jira_password,
    String $nick_password,
    Array $clusters = $profile::kubernetes::params::clusters,
    String $image_tag = 'latest'

) inherits profile::kubernetes::params {

  require profile::kubernetes::kubectl
  require profile::kubernetes::resources::nginx
  require profile::kubernetes::resources::lego

  $clusters.each | $cluster | {
    $context = $cluster['clustername']

    file { "${profile::kubernetes::params::resources}/${context}/chatbot_jenkinsadmin":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    profile::kubernetes::apply { "chatbot_jenkinsadmin/namespace.yaml on ${context}":
      context  => $context,
      resource => 'chatbot_jenkinsadmin/namespace.yaml'
    }

    profile::kubernetes::apply { "chatbot_jenkinsadmin/secret.yaml on ${context}":
      context    => $context,
      parameters => {
        'github_login'    => base64('encode', $github_login, 'strict'),
        'github_password' => base64('encode', $github_password, 'strict'),
        'jira_login'      => base64('encode', $jira_login, 'strict'),
        'jira_password'   => base64('encode', $jira_password, 'strict')
      },
      resource   => 'chatbot_jenkinsadmin/secret.yaml'
    }

    profile::kubernetes::apply { "chatbot_jenkinsadmin/deployment.yaml on ${context}":
      context    => $context,
      parameters => {
        'image_tag'     =>  $image_tag,
        'nick_password' => $nick_password
      },
      resource   => 'chatbot_jenkinsadmin/deployment.yaml'
    }

    profile::kubernetes::reload { "chatbot_jenkinsadmin pods on ${context}":
      app        => 'chatbot_jenkinsadmin',
      context    => $context,
      depends_on => [
        'chatbot_jenkinsadmin/secret.yaml'
      ]
    }
  }
}
