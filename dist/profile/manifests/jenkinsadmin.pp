#
# IRC bot that runs most project related tasks
# containerized in https://github.com/jenkins-infra/ircbot

#############################################################
##                                                         ##
##  THIS CLASS IS DEPRECATED IN FAVOR OF                   ##
##  profile::kubernetes::resources::chatbot_jenkinsadmin   ##
##                                                         ##
#############################################################

class profile::jenkinsadmin (
  # Parameters supplied by Hiera
  $github_login,
  $github_password,
  $jira_login,
  $jira_password,
  $nick_password,
  $image_tag = undef,
) {
  include profile::docker

  validate_string($image_tag)
  $user = 'ircbot'

  docker::image { 'jenkinsciinfra/ircbot':
    ensure    => absent,
    image_tag => $image_tag,
  }

  docker::run { 'ircbot':
    # The entrypoint in the container allows passing the nick password through
    # to the invocation of the Java command, since the IRC bot .jar file
    # requires:
    #    java -jar /home/ircbot/*.jar $NICKPASSWORD
    ensure   => 'absent',
    command  => $nick_password,
    volumes  => ['/home/ircbot/.github:/home/ircbot/.github',
      '/home/ircbot/.jenkins-ci.org:/home/ircbot/.jenkins-ci.org',
    ],
    username => 'ircbot',
    image    => "jenkinsciinfra/ircbot:${image_tag}",
    require  => [Docker::Image['jenkinsciinfra/ircbot'],
      File['/home/ircbot/.github'],
      File['/home/ircbot/.jenkins-ci.org'],
    ],
  }

  user { $user:
    ensure     => absent,
    shell      => '/bin/false',
    # hard-coding because this is what we already have on spinach
    uid        => '1013',
    managehome => true,
  }

  file { '/home/ircbot/.github':
    ensure  => absent,
    owner   => $user,
    require => User[$user],
    content => template("${module_name}/jenkinsadmin/dot-github.erb"),
    mode    => '0600',
    notify  => Service['docker-ircbot'],
  }

  file { '/home/ircbot/.jenkins-ci.org':
    ensure  => absent,
    owner   => $user,
    content => template("${module_name}/jenkinsadmin/dot-jenkins.erb"),
    mode    => '0600',
    notify  => Service['docker-ircbot'],
  }
}
