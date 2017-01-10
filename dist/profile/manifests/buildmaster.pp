#
# Profile for configuring the bare necessities to running a Jenkins master
#
# Parameters
# ----------
#
# ci_fqdn = 'ci.jenkins.io' (Default)
#   Define the fully-qualified domain name for this Jenkins master. This value
#   will be used for Jenkins' own configuration as well as Apache virtual hosts
#   and certificates
#
# letsencrypt = true (Default)
#   Enable letsencrypt configuration, for this to work the Jenkins host has to
#   be on the public internet
#
class profile::buildmaster(
  $ci_fqdn     = 'ci.jenkins.io',
  $letsencrypt = true,
  $plugins     = undef,
  $proxy_port  = 443,
  $jenkins_home= '/var/lib/jenkins',
) {
  include ::stdlib
  include ::apache
  include apache::mod::proxy
  include apache::mod::headers
  include apache::mod::rewrite

  validate_string($ci_fqdn)
  validate_bool($letsencrypt)
  validate_array($plugins)

  include profile::apachemisc
  include profile::docker
  include profile::firewall

  if $letsencrypt {
    include profile::letsencrypt
  }

  $ldap_url    = hiera('ldap_url')
  $ldap_dn     = hiera('ldap_dn')
  $ldap_admin_dn = hiera('ldap_admin_dn')
  $ldap_admin_password = hiera('ldap_admin_password')

  $ssh_dir = "${jenkins_home}/.ssh"
  $ssh_cli_key = 'jenkins-cli-key'

  $script_dir = '/usr/share/jenkins'
  $cli_script = "${script_dir}/idempotent-cli"
  $lockbox_script = "${script_dir}/lockbox.groovy"

  $docroot = "/var/www/${ci_fqdn}"
  $apache_log_dir = "/var/log/apache2/${ci_fqdn}"


  class { '::jenkins':
    # Preventing the jenkins module from managing the package for us, since
    # we're using the Docker container, see:
    # https://issues.jenkins-ci.org/browse/INFRA-916
    version        => absent,
    repo           => false,
    service_enable => false,
    service_ensure => stopped,
    cli            => false,
  }

  docker::run { 'jenkins':
    image            => 'jenkins',
    # This is a "clever" hack to force the init script to pass the numeric UID
    # through on `docker run`. Since passing the string 'jenkins' doesn't
    # actually map the UIDs properly. Using the extra_parameters option because
    # the `username` parameter will get shellescaped in the docker_run_flags()
    # function provided by garethr/docker
    extra_parameters => '-u `id -u jenkins`:`id -g jenkins`',
    # Hard-coding some environment variables because there is no "parent" shell
    # environment to inherit some of these environment settings from.
    # Additionally, Jenkins picks up `user.home` as "?" without the explicit
    # JAVA_OPTS override, breaking the current azure plugin:
    # https://github.com/jenkinsci/azure-slave-plugin/issues/56
    env              => [
      "HOME=${jenkins_home}",
      'USER=jenkins',
      'JAVA_OPTS="-Duser.home=/var/jenkins_home  -Djenkins.install.runSetupWizard=false -Djenkins.model.Jenkins.slaveAgentPort=50000 -Dhudson.model.WorkspaceCleanupThread.retainForDays=2"',
      'JENKINS_OPTS="--httpKeepAliveTimeout=60000"',
    ],
    ports            => ['8080:8080', '50000:50000', '22222:22222'],
    volumes          => ["${jenkins_home}:/var/jenkins_home"],
    pull_on_start    => true,
    require          => [
        File[$jenkins_home],
        User['jenkins'],
    ],
  }

  # Make sure the old init script is gone, since the package removal won't
  # handle it
  # https://issues.jenkins-ci.org/browse/INFRA-916
  file { '/etc/init.d/jenkins':
    ensure => absent,
  }
  file { '/etc/default/jenkins':
    ensure  => present,
    content => 'This file is no longer used',
  }

  file { $script_dir:
    ensure => directory,
  }

  # Jenkins custom-bootstrapping
  #
  # These files should be laid down on the file system before Jenkins starts
  # such that they're loaded properly
  ##############################################################################
  file { "${jenkins_home}/init.groovy.d":
    ensure  => directory,
    owner   => 'jenkins',
    require => [
        User['jenkins'],
        File[$jenkins_home],
    ],
  }

  file { "${jenkins_home}/init.groovy.d/enable-ssh-port.groovy":
    ensure  => present,
    owner   => 'jenkins',
    source  => "puppet:///modules/${module_name}/buildmaster/enable-ssh-port.groovy",
    require => [
        User['jenkins'],
        File[$jenkins_home],
    ],
    before  => Docker::Run['jenkins'],
    notify  => Service['docker-jenkins'],
  }

  file { "${jenkins_home}/init.groovy.d/set-up-git.groovy":
    ensure  => present,
    owner   => 'jenkins',
    source  => "puppet:///modules/${module_name}/buildmaster/set-up-git.groovy",
    require => [
        User['jenkins'],
        File[$jenkins_home],
    ],
    before  => Docker::Run['jenkins'],
    notify  => Service['docker-jenkins'],
  }
  ##############################################################################


  # Prepare Jenkins instance-only SSH keys for CLI usage
  ##############################################################################
  file { $ssh_dir :
    ensure  => directory,
    owner   => 'jenkins',
    mode    => '0700',
    require => [
        User['jenkins'],
        File[$jenkins_home],
    ],
  }
  exec { 'generate-cli-ssh-key':
    require => File[$jenkins_home],
    creates => "${ssh_dir}/${ssh_cli_key}",
    command => "/usr/bin/ssh-keygen -b 4096 -q -f ${ssh_dir}/${ssh_cli_key} -N ''",
  }
  ##############################################################################


  # Bootstrap the Jenkins internal (to Jenkins) user entity for CLI work
  ##############################################################################
  file { "${script_dir}/create-jenkins-cli-user":
    ensure  => present,
    require => File[$script_dir],
    source  => "puppet:///modules/${module_name}/buildmaster/create-jenkins-cli-user",
    mode    => '0755',
  }

  exec { 'create-jenkins-cli-user':
    creates => "${jenkins_home}/users/jenkins/config.xml",
    command => "${script_dir}/create-jenkins-cli-user",
    before  => Docker::Run['jenkins'],
    require => [
      File[$jenkins_home],
      File["${script_dir}/create-jenkins-cli-user"],
    ],
  }
  ##############################################################################

  # CLI support
  ##############################################################################
  file { $cli_script:
    ensure  => present,
    require => File[$script_dir],
    source  => "puppet:///modules/${module_name}/buildmaster/idempotent-cli",
    mode    => '0755',
  }
  exec { 'safe-restart-jenkins-via-ssh-cli':
    require     => [
      File[$cli_script],
    ],
    command     => "${cli_script} safe-restart",
    refreshonly => true,
  }
  ##############################################################################


  file { $lockbox_script :
    ensure  => present,
    require => File[$script_dir],
    content =>template("${module_name}/buildmaster/lockbox.groovy.erb"),
  }
  profile::jenkinsgroovy { 'lock-down-jenkins':
    path    => $lockbox_script,
    require => [
      File[$lockbox_script],
      File[$cli_script],
      Exec['generate-cli-ssh-key'],
    ],
  }

  profile::jenkinsplugin { $plugins:
    # Only install plugins after we've secured Jenkins, that seems reasonable
    require => [
      File[$cli_script],
      Exec['generate-cli-ssh-key'],
      Profile::Jenkinsgroovy['lock-down-jenkins'],
    ],
  }

  exec { 'jenkins-reload-config':
    command     => "${cli_script} reload-configuration",
    refreshonly => true,
    require     => [
      File[$cli_script],
      Exec['generate-cli-ssh-key'],
    ],
  }

  file { [$apache_log_dir, $docroot,]:
    ensure  => directory,
    require => Package['httpd'],
  }

  apache::vhost { $ci_fqdn:
    serveraliases         => [
      # Give all our buildmaster profiles this server alias; it's easier than
      # parameterizing it for compatibility's sake
      'ci.jenkins-ci.org',
    ],
    require               => [
      Docker::Run['jenkins'],
      File[$docroot],
      # We need our installation to be secure before we allow access
      Profile::Jenkinsgroovy['lock-down-jenkins'],
    ],
    port                  => 443,
    override              => 'All',
    ssl                   => true,
    docroot               => $docroot,
    error_log_file        => "${ci_fqdn}/error.log",
    access_log_pipe       => "|/usr/bin/rotatelogs ${apache_log_dir}/access.log.%Y%m%d%H%M%S 604800",
    proxy_preserve_host   => true,
    allow_encoded_slashes => 'on',
    custom_fragment       => "
RequestHeader set X-Forwarded-Proto \"https\"
RequestHeader set X-Forwarded-Port \"${proxy_port}\"

RewriteEngine on
# Block abusive software which is default configured to hit our Jenkins
# instance(s). These are typically Build Notifiers that use us as a default
# since we're public, not anymore for you!
RewriteCond %{HTTP_USER_AGENT} YisouSpider|Catlight*|CheckmanJenkins [NC]
RewriteRule ^.* \"https://jenkins.io/infra/ci-redirects/\"  [L]

# Blackhole all the /cli requests over HTTP
RewriteRule ^/cli.* https://github.com/jenkinsci-cert/SECURITY-218
",
    proxy_pass            => [
      {
        path         => '/',
        url          => 'http://localhost:8080/',
        keywords     => ['nocanon'],
        reverse_urls => ['http://localhost:8080/'],
      },
    ],
  }

  apache::vhost { "${ci_fqdn} unsecured":
    serveraliases   => [
      # Give all our buildmaster profiles this server alias; it's easier than
      # parameterizing it for compatibility's sake
      'ci.jenkins-ci.org',
    ],
    servername      => $ci_fqdn,
    port            => 80,
    docroot         => $docroot,
    redirect_status => 'permanent',
    redirect_dest   => "https://${ci_fqdn}/",
    error_log_file  => "${ci_fqdn}/error_nonssl.log",
    access_log_pipe => "|/usr/bin/rotatelogs ${apache_log_dir}/access_nonssl.log.%Y%m%d%H%M%S 604800",
    require         => Apache::Vhost[$ci_fqdn],
  }


  # This is a legacy role imported from infra-puppet, thus the goofy numbering
  firewall { '108 Jenkins CLI port' :
    proto  => 'tcp',
    port   => 47278,
    action => 'accept',
  }

  firewall { '801 Allow Jenkins web access only on localhost':
    proto   => 'tcp',
    port    => 8080,
    action  => 'accept',
    iniface => 'lo',
  }

  firewall { '802 Block external Jenkins web access':
    proto  => 'tcp',
    port   => 8080,
    action => 'drop',
  }

  firewall { '803 Expose JNLP port':
    proto  => 'tcp',
    port   => 50000,
    action => 'accept',
  }

  firewall { '810 Jenkins CLI SSH':
    proto  => 'tcp',
    port   => 22222,
    action => 'accept',
  }

  # We can only acquire certs in production due to the way the letsencrypt
  # challenge process works
  if (($letsencrypt == true) and ($::environment == 'production') and ($::vagrant != '1')) {
    letsencrypt::certonly { $ci_fqdn:
      domains     => [$ci_fqdn],
      plugin      => 'apache',
      manage_cron => true,
    }

    Apache::Vhost <| title == $ci_fqdn |> {
      ssl_key       => "/etc/letsencrypt/live/${ci_fqdn}/privkey.pem",
      # When Apache is upgraded to >= 2.4.8 this should be changed to
      # fullchain.pem
      ssl_cert      => "/etc/letsencrypt/live/${ci_fqdn}/cert.pem",
      ssl_chain     => "/etc/letsencrypt/live/${ci_fqdn}/chain.pem",
    }
  }
}
