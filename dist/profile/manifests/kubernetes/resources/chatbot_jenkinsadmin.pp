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

    $github_credentials = "login=${github_login}\npassword=${github_password}\n"
    $jira_credentials = "userName=${jira_login}\npassword=${jira_password}\n"

    profile::kubernetes::apply { "chatbot_jenkinsadmin/secret.yaml on ${context}":
      context    => $context,
      parameters => {
        'github'        => base64('encode', $github_credentials, 'strict'),
        'jira'          => base64('encode', $jira_credentials , 'strict'),
        'nick_password' => base64('encode', $nick_password, 'strict')
      },
      resource   => 'chatbot_jenkinsadmin/secret.yaml'
    }

    profile::kubernetes::apply { "chatbot_jenkinsadmin/deployment.yaml on ${context}":
      context    => $context,
      parameters => {
        'image_tag'     =>  $image_tag
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
