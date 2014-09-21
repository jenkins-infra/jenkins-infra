#
# IRC bot that runs most project related tasks
# containerized in https://github.com/jenkins-infra/ircbot
class profile::jenkinsadmin (
  # Parameters supplied by Hiera
  $github_login,
  $github_password,
  $jira_login,
  $jira_password,
  $nick_password,
) {
  include profile::docker

  # Tag is the docker container image tag from our build process, this job:
  # <https://ci.jenkins-ci.org/view/Infrastructure/job/infra_ircbot>
  $tag = 'build16'
  $user = 'ircbot'

  docker::image { 'jenkinsciinfra/ircbot':
    image_tag => $tag,
  }

  docker::run { 'ircbot':
    # The entrypoint in the container allows passing the nick password through
    # to the invocation of the Java command, since the IRC bot .jar file
    # requires:
    #    java -jar /home/ircbot/*.jar $NICKPASSWORD
    command  => $nick_password,
    volumes  => ['/home/ircbot/.github:/home/ircbot/.github',
                '/home/ircbot/.jenkins-ci.org:/home/ircbot/.jenkins-ci.org',
    ],
    username => 'ircbot',
    image    => "jenkinsciinfra/ircbot:${tag}",
    require  => [Docker::Image['jenkinsciinfra/ircbot'],
                File['/home/ircbot/.github'],
                File['/home/ircbot/.jenkins-ci.org'],
    ],
  }

  # 'restart ircbot' won't do because it will not reload the configuration
  exec { 'restart-ircbot':
    refreshonly => true,
    command     => '/sbin/stop docker-ircbot; /sbin/start docker-ircbot',
  }

  # The File[/etc/init/docker-ircbot.conf] resource is declared by the
  # module, but we still need to punt the container if the config changes
  File <| title == '/etc/init/docker-ircbot.conf' |> {
    notify  => Exec['restart-ircbot'],
  }

  user { $user:
    shell      => '/bin/false',
    # hard-coding because this is what we already have on spinach
    uid        => '1013',
    managehome => true,
  }

  file { '/home/ircbot/.github':
    owner   => $user,
    require => User[$user],
    content => template("${module_name}/jenkinsadmin/dot-github.erb"),
    mode    => '0600',
    notify  => Exec['restart-ircbot'],
  }

  file { '/home/ircbot/.jenkins-ci.org':
    owner   => $user,
    require => User[$user],
    content => template("${module_name}/jenkinsadmin/dot-jenkins.erb"),
    mode    => '0600',
    notify  => Exec['restart-ircbot'],
  }
}
