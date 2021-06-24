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
  $anonymous_access                = false,
  $admin_ldap_groups               = ['admins'],
  $ci_fqdn                         = 'ci.jenkins.io',
  $ci_resource_domain              = 'assets.ci.jenkins.io',
  $docker_image                    = 'jenkins/jenkins',
  $docker_tag                      = 'lts-alpine',
  $letsencrypt                     = true,
  $plugins                         = undef,
  $proxy_port                      = 443,
  $jenkins_home                    = '/var/lib/jenkins',
  $groovy_init_enabled             = false,
  $groovy_d_enable_ssh_port        = 'absent',
  $groovy_d_set_up_git             = 'absent',
  $groovy_d_agent_security         = 'absent',
  $groovy_d_pipeline_configuration = 'absent',
  $groovy_d_lock_down_jenkins      = 'absent',
  $groovy_d_terraform_credentials  = 'absent',
  $memory_limit                    = '1g',
  $java_opts                       = '-XshowSettings:vm -server -Xloggc:/var/jenkins_home/gc-%t.log -XX:NumberOfGCLogFiles=5 -XX:+UseGCLogFileRotation -XX:GCLogFileSize=20m -XX:+PrintGC -XX:+PrintGCDateStamps -XX:+PrintGCDetails -XX:+PrintHeapAtGC -XX:+PrintGCCause -XX:+PrintTenuringDistribution -XX:+PrintReferenceGC -XX:+PrintAdaptiveSizePolicy -XX:+AlwaysPreTouch -XX:+UseG1GC -XX:+ExplicitGCInvokesConcurrent -XX:+ParallelRefProcEnabled -XX:+UseStringDeduplication -XX:+UnlockExperimentalVMOptions -XX:G1NewSizePercent=20 -XX:+UnlockDiagnosticVMOptions -XX:G1SummarizeRSetStatsPeriod=1 -Duser.home=/var/jenkins_home -Djenkins.install.runSetupWizard=false -Djenkins.model.Jenkins.slaveAgentPort=50000 -Dhudson.model.WorkspaceCleanupThread.retainForDays=2'
) {
  include ::stdlib
  include ::apache
  include apache::mod::alias
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

  $ldap_url    = lookup('ldap_url')
  $ldap_dn     = lookup('ldap_dn')
  $ldap_admin_dn = lookup('ldap_admin_dn')
  $ldap_admin_password = lookup('ldap_admin_password')

  $ssh_dir = "${jenkins_home}/.ssh"
  $ssh_cli_key = 'jenkins-cli-key'

  $script_dir = '/usr/share/jenkins'
  $cli_script = "${script_dir}/idempotent-cli"
  $lockbox_script = "${script_dir}/lockbox.groovy"
  $groovy_d = "${jenkins_home}/init.groovy.d"

  $docroot = "/var/www/${ci_fqdn}"
  $apache_log_dir = "/var/log/apache2/${ci_fqdn}"
  $apache_log_dir_assets = "/var/log/apache2/${ci_resource_domain}"

  group { 'jenkins':
    ensure => present,
  }

  user { 'jenkins':
    ensure => present,
    home   => $jenkins_home,
  }

  file { $jenkins_home:
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins'
  }

  file { "${jenkins_home}/gc":
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins'
  }

  file { '/etc/default/jenkins':
    ensure  => absent,
  }
  # Make sure the old init script is gone, since the package removal won't
  # handle it
  # https://issues.jenkins-ci.org/browse/INFRA-916
  # No-op, just to make puppet-jenkins STFU
  file { '/etc/init.d/jenkins' :
    ensure  => absent,
  }

  file { $script_dir:
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins'
  }

  # Jenkins custom-bootstrapping
  #
  # These files should be laid down on the file system before Jenkins starts
  # such that they're loaded properly
  ##############################################################################

  # $groovy_init_enabled is used as a safeguard to disable all init groovy script
  # if we don't have to use any of them like on cert.ci
  unless $groovy_init_enabled {
    file { $groovy_d:
      ensure  => directory,
      owner   => 'jenkins',
      group   => 'jenkins',
      purge   => true,
      recurse => true,
      require => [
          File[$jenkins_home],
      ],
    }

  } else {
    file { $groovy_d:
      ensure  => directory,
      owner   => 'jenkins',
      group   => 'jenkins',
      require => [
          User['jenkins'],
          File[$jenkins_home],
      ],
    }

    file { "${groovy_d}/enable-ssh-port.groovy":
      ensure  => $groovy_d_enable_ssh_port,
      owner   => 'jenkins',
      group   => 'jenkins',
      source  => "puppet:///modules/${module_name}/buildmaster/enable-ssh-port.groovy",
      require => [
          User['jenkins'],
          File[$groovy_d],
      ],
      before  => Docker::Run['jenkins'],
      notify  => Service['docker-jenkins'],
    }

    file { "${groovy_d}/set-up-git.groovy":
      ensure  => $groovy_d_set_up_git,
      owner   => 'jenkins',
      group   => 'jenkins',
      source  => "puppet:///modules/${module_name}/buildmaster/set-up-git.groovy",
      require => [
          User['jenkins'],
          File[$groovy_d],
      ],
      before  => Docker::Run['jenkins'],
      notify  => Service['docker-jenkins'],
    }

    file { "${groovy_d}/agent-security.groovy":
      ensure  => $groovy_d_agent_security,
      owner   => 'jenkins',
      group   => 'jenkins',
      source  => "puppet:///modules/${module_name}/buildmaster/agent-security.groovy",
      require => [
          User['jenkins'],
          File[$groovy_d],
      ],
      before  => Docker::Run['jenkins'],
      notify  => Service['docker-jenkins'],
    }

    file { "${groovy_d}/pipeline-configuration.groovy":
      ensure  => $groovy_d_pipeline_configuration,
      owner   => 'jenkins',
      group   => 'jenkins',
      source  => "puppet:///modules/${module_name}/buildmaster/pipeline-configuration.groovy",
      require => [
          User['jenkins'],
          File[$groovy_d],
      ],
      before  => Docker::Run['jenkins'],
      notify  => Service['docker-jenkins'],
    }

    file { "${groovy_d}/lock-down-jenkins.groovy":
      ensure  => $groovy_d_lock_down_jenkins,
      owner   => 'jenkins',
      group   => 'jenkins',
      require => [
          User['jenkins'],
          File[$groovy_d],
          Exec['generate-cli-ssh-key'],
      ],
      content => template("${module_name}/buildmaster/lockbox.groovy.erb"),
      before  => Docker::Run['jenkins'],
      notify  => Service['docker-jenkins'],
    }

    file { "${groovy_d}/terraform-credentials.groovy":
      ensure  => $groovy_d_terraform_credentials,
      owner   => 'jenkins',
      group   => 'jenkins',
      require => [
          File[$groovy_d],
          File["${ssh_dir}/azure_k8s.pub"],
      ],
      source  => "puppet:///modules/${module_name}/buildmaster/terraform-credentials.groovy",
      before  => Docker::Run['jenkins'],
      notify  => Service['docker-jenkins'],
    }
  }
  ##############################################################################

  docker::run { 'jenkins':
    memory_limit     => $memory_limit,
    image            => "${docker_image}:${docker_tag}",
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
    # Quote inside env variable must be escaped as puppet generate a bash script
    env              => [
      "HOME=${jenkins_home}",
      'USER=jenkins',
      "JAVA_OPTS=${java_opts}",
      'JENKINS_OPTS=--httpKeepAliveTimeout=60000',
    ],
    ports            => ['8080:8080', '50000:50000', '22222:22222'],
    volumes          => ["${jenkins_home}:/var/jenkins_home"],
    pull_on_start    => true,
    require          => [
        File[$jenkins_home],
        User['jenkins'],
    ],
  }

  # Prepare Jenkins instance-only SSH keys for CLI usage
  ##############################################################################
  file { $ssh_dir :
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
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

  file { "${ssh_dir}/azure_k8s":
    ensure  => absent,
    mode    => '0600',
    content => lookup('azure::k8s::management_ssh_privkey'),
    require => [
        File[$ssh_dir],
    ],
  }

  file { "${ssh_dir}/azure_k8s.pub":
    ensure  => absent,
    mode    => '0644',
    content => lookup('azure::k8s::management_ssh_pubkey'),
    require => [
        File[$ssh_dir],
    ],
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
    ensure  => absent,
  }

  profile::jenkinsplugin { $plugins:
    # Only install plugins after we've secured Jenkins, that seems reasonable
    require => [
      File[$cli_script],
      File[$groovy_d],
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

  file { [$apache_log_dir, $docroot, $apache_log_dir_assets]:
    ensure  => directory,
    require => Package['httpd'],
  }

  file { "${docroot}/empty.json" :
    ensure  => file,
    content => '{}',
    mode    => '0644',
    require => File[$docroot],
  }

  file { "${docroot}/empty.xml" :
    ensure  => file,
    content => '<nope/>',
    mode    => '0644',
    require => File[$docroot],
  }

  apache::vhost { $ci_fqdn:
    serveraliases         => [
      # Give all our buildmaster profiles this server alias; it's easier than
      # parameterizing it for compatibility's sake
      'ci.jenkins-ci.org', $ci_resource_domain,
    ],
    require               => [
      Docker::Run['jenkins'],
      File[$docroot],
      # We need our installation to be secure before we allow access
      File[$groovy_d],
    ],
    port                  => 443,
    override              => 'All',
    ssl                   => true,
    docroot               => $docroot,
    error_log_file        => "${ci_fqdn}/error.log",
    access_log_pipe       => "|/usr/bin/rotatelogs -t ${apache_log_dir}/access.log.%Y%m%d%H%M%S 86400",
    proxy_preserve_host   => true,
    allow_encoded_slashes => 'on',
    custom_fragment       => "
RequestHeader set X-Forwarded-Proto \"https\"
RequestHeader set X-Forwarded-Port \"${proxy_port}\"
RequestHeader set X-Forwarded-Host \"${ci_fqdn}\"

RewriteEngine on

RewriteCond %{REQUEST_FILENAME} ^(.*)api/xml(.*)$ [NC]
RewriteRule ^.* \"https://jenkins.io/infra/ci-redirects/\"  [L]

# Abusive Chinese bot that ignores robots.txt
RewriteCond %{HTTP_USER_AGENT}  Sogou [NC]
RewriteRule \".?\" \"-\" [F]

# Black hole all traffic to routes like /view/All/people/ which is pretty much
# hit illegitimately used anyways
# See thread dump here: https://gist.github.com/rtyler/f8d02e0c5ff11e03da4e331a0f2ca280
RewriteCond %{REQUEST_FILENAME} ^(.*)people(.*)$ [NC]
RewriteRule ^.* \"https://jenkins.io/infra/ci-redirects/\"  [L]

# Send unauthenticated api/json or api/python requests to `empty.json` to prevent abusive clients
# (checkman) from receiving an invalid JSON response and repeatedly attempting
# to hammer us to get a better response. Works for Python API as well.
RewriteCond \"%{HTTP:Authorization}\" !^Basic
RewriteRule (.*)/api/(json|python)(/|$)(.*) /empty.json
# Analogously for XML.
RewriteCond \"%{HTTP:Authorization}\" !^Basic
RewriteRule (.*)/api/xml(/|$)(.*) /empty.xml

# Loading our Proxy rules ourselves from a custom fragment since the
# puppetlabs/apache module doesn't support ordering of both proxy_pass and
# proxy_pass_match configurations
ProxyRequests Off
ProxyPreserveHost On
ProxyPass / http://localhost:8080/ nocanon
ProxyPassReverse / http://localhost:8080/
",
  }

  apache::vhost { $ci_resource_domain:
    require               => [
      Docker::Run['jenkins'],
      File[$docroot],
      # We need our installation to be secure before we allow access
      File[$groovy_d],
    ],
    port                  => 443,
    override              => 'All',
    ssl                   => true,
    docroot               => $docroot,
    error_log_file        => "${ci_resource_domain}/error.log",
    access_log_pipe       => "|/usr/bin/rotatelogs -t ${apache_log_dir}/access.log.%Y%m%d%H%M%S 86400",
    proxy_preserve_host   => true,
    allow_encoded_slashes => 'on',
    custom_fragment       => "
RequestHeader set X-Forwarded-Proto \"https\"
RequestHeader set X-Forwarded-Port \"${proxy_port}\"
RequestHeader set X-Forwarded-Host \"${ci_resource_domain}\"

RewriteEngine on

RewriteCond %{REQUEST_FILENAME} ^(.*)api/xml(.*)$ [NC]
RewriteRule ^.* \"https://jenkins.io/infra/ci-redirects/\"  [L]

# Abusive Chinese bot that ignores robots.txt
RewriteCond %{HTTP_USER_AGENT}  Sogou [NC]
RewriteRule \".?\" \"-\" [F]

# Black hole all traffic to routes like /view/All/people/ which is pretty much
# hit illegitimately used anyways
# See thread dump here: https://gist.github.com/rtyler/f8d02e0c5ff11e03da4e331a0f2ca280
RewriteCond %{REQUEST_FILENAME} ^(.*)people(.*)$ [NC]
RewriteRule ^.* \"https://jenkins.io/infra/ci-redirects/\"  [L]

# Send unauthenticated api/json or api/python requests to `empty.json` to prevent abusive clients
# (checkman) from receiving an invalid JSON response and repeatedly attempting
# to hammer us to get a better response. Works for Python API as well.
RewriteCond \"%{HTTP:Authorization}\" !^Basic
RewriteRule (.*)/api/(json|python)(/|$)(.*) /empty.json
# Analogously for XML.
RewriteCond \"%{HTTP:Authorization}\" !^Basic
RewriteRule (.*)/api/xml(/|$)(.*) /empty.xml

# Loading our Proxy rules ourselves from a custom fragment since the
# puppetlabs/apache module doesn't support ordering of both proxy_pass and
# proxy_pass_match configurations
ProxyRequests Off
ProxyPreserveHost On
ProxyPass / http://localhost:8080/ nocanon
ProxyPassReverse / http://localhost:8080/
",
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
    access_log_pipe => '/dev/null',
    require         => Apache::Vhost[$ci_fqdn],
  }

  apache::vhost { "${ci_resource_domain} unsecured":
    servername      => $ci_resource_domain,
    port            => 80,
    docroot         => $docroot,
    redirect_status => 'permanent',
    redirect_dest   => "https://${ci_resource_domain}/",
    error_log_file  => "${ci_resource_domain}/error_nonssl.log",
    access_log_pipe => '/dev/null',
    require         => Apache::Vhost[$ci_resource_domain],
  }

  # This is a legacy role imported from infra-puppet, thus the goofy numbering
  firewall { '108 Jenkins CLI port' :
    proto  => 'tcp',
    dport  => 47278,
    action => 'accept',
  }

  firewall { '801 Allow Jenkins web access only on localhost':
    proto   => 'tcp',
    dport   => 8080,
    action  => 'accept',
    iniface => 'lo',
  }

  firewall { '802 Block external Jenkins web access':
    proto  => 'tcp',
    dport  => 8080,
    action => 'drop',
  }

  firewall { '803 Expose JNLP port':
    proto  => 'tcp',
    dport  => 50000,
    action => 'accept',
  }

  firewall { '810 Jenkins CLI SSH':
    proto  => 'tcp',
    dport  => 22222,
    action => 'accept',
  }

  # We can only acquire certs in production due to the way the letsencrypt
  # challenge process works
  if (($letsencrypt == true) and ($::environment == 'production') and ($::vagrant != '1')) {
    letsencrypt::certonly { $ci_fqdn:
      domains     => [$ci_fqdn, $ci_resource_domain],
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

    letsencrypt::certonly { $ci_resource_domain:
      domains     => [$ci_resource_domain],
      plugin      => 'apache',
      manage_cron => true,
    }

    Apache::Vhost <| title == $ci_resource_domain |> {
      ssl_key       => "/etc/letsencrypt/live/${ci_resource_domain}/privkey.pem",
      # When Apache is upgraded to >= 2.4.8 this should be changed to
      # fullchain.pem
      ssl_cert      => "/etc/letsencrypt/live/${ci_resource_domain}/cert.pem",
      ssl_chain     => "/etc/letsencrypt/live/${ci_resource_domain}/chain.pem",
    }
  }
}
