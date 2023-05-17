#
# Profile for configuring the bare necessities to run a Jenkins controller
#
# Parameters
# ----------
#
# ci_fqdn = 'ci.jenkins.io' (Default)
#   Define the fully-qualified domain name for this Jenkins controller. This value
#   will be used for Jenkins' own configuration as well as Apache virtual hosts
#   and certificates
#
# letsencrypt = true (Default)
#   Enable letsencrypt configuration, for this to work the Jenkins host has to
#   be on the public internet
#
class profile::jenkinscontroller (
  Boolean $anonymous_access                    = false,
  Array $admin_ldap_groups                     = ['admins'],
  Stdlib::Fqdn $ci_fqdn                        = '',
  String $ci_resource_domain                   = '',
  String $docker_image                         = 'jenkins/jenkins',
  String $docker_tag                           = 'lts-jdk11',
  String $docker_container_name                = 'jenkins',
  Boolean $letsencrypt                         = true,
  Optional[Array] $plugins                     = undef,
  Stdlib::Port $proxy_port                     = 443,
  Stdlib::Absolutepath $jenkins_home           = '/var/lib/jenkins',
  Stdlib::Absolutepath $container_jenkins_home = '/var/jenkins_home',
  Boolean $groovy_init_enabled                 = false,
  String $groovy_d_set_up_git                  = 'absent',
  String $groovy_d_lock_down_jenkins           = 'absent',
  Hash $jcasc                                  = {},
  Boolean $block_remote_access_api             = false,
  String $memory_limit                         = '1g',
  String $java_opts = "-server \
-Xlog:gc*=info,ref*=debug,ergo*=trace,age*=trace:file=${container_jenkins_home}/gc/gc.log::filecount=5,filesize=40M \
-XX:+UnlockExperimentalVMOptions \
-XX:+UseG1GC \
-XX:+ParallelRefProcEnabled \
-XX:+UnlockDiagnosticVMOptions \
-Duser.home=${container_jenkins_home} \
-Djenkins.install.runSetupWizard=false \
-Djenkins.model.Jenkins.slaveAgentPort=50000 \
-Dhudson.model.WorkspaceCleanupThread.retainForDays=2 \
-Dio.jenkins.plugins.artifact_manager_jclouds.s3.S3BlobStoreConfig.deleteStashes=true", # Must be Java 11 compliant!
) {
  include stdlib # Required to allow using stlib methods and custom datatypes
  include apache
  include apache::mod::alias
  include apache::mod::proxy
  include apache::mod::headers
  include apache::mod::rewrite
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

  $script_dir = '/usr/share/jenkins'
  $groovy_d = "${jenkins_home}/init.groovy.d"
  $docroot = "/var/www/${ci_fqdn}"
  $apache_log_dir = "/var/log/apache2/${ci_fqdn}"

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
    group  => 'jenkins',
  }

  file { "${jenkins_home}/gc":
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  file { $script_dir:
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
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

    file { "${groovy_d}/set-up-git.groovy":
      ensure  => $groovy_d_set_up_git,
      owner   => 'jenkins',
      group   => 'jenkins',
      source  => "puppet:///modules/${module_name}/jenkinscontroller/set-up-git.groovy",
      require => [
        User['jenkins'],
        File[$groovy_d],
      ],
      before  => Docker::Run[$docker_container_name],
      notify  => Service['docker-jenkins'],
    }

    file { "${groovy_d}/lock-down-jenkins.groovy":
      ensure  => $groovy_d_lock_down_jenkins,
      owner   => 'jenkins',
      group   => 'jenkins',
      require => [
        User['jenkins'],
        File[$groovy_d],
      ],
      content => template("${module_name}/jenkinscontroller/lockbox.groovy.erb"),
      before  => Docker::Run[$docker_container_name],
      notify  => Service['docker-jenkins'],
    }
  }
  ##############################################################################

  ##############################################################################
  # JCasc Files: if provided through hieradata, then add these files in the ${jenkins_home}/casc.d/
  ##############################################################################
  $jcasc_default_config= {
    enabled => false, # Disabled by default to avoid messing up with unmanaged instances
    custom_configs => [],
    reload_token => '',
    # Default JCasc templates shared by all Jenkins controllers.
    # Use hieradata attribute to opt-out (see below), or override with an additional file (lexicographic).
    common_configs => [
      # Opt-out with `profile::jenkinscontroller::jcasc.cloud_agents: {}`
      'jenkinscontroller/casc/clouds.yaml.erb',
      # Opt-out with `profile::jenkinscontroller::jcasc.global_libraries: false`
      'jenkinscontroller/casc/global-libraries.yaml.erb',
      # Opt-out with `profile::jenkinscontroller::jcasc.jenkins_global: false`
      'jenkinscontroller/casc/jenkins.yaml.erb',
      # Opt-out with `profile::jenkinscontroller::jcasc.cloud_agents: {}`
      'jenkinscontroller/casc/permanent-agents.yaml.erb',
      # Opt-out with `profile::jenkinscontroller::jcasc.tools: {}`
      'jenkinscontroller/casc/tools.yaml.erb',
      # Opt-out with `profile::jenkinscontroller::jcasc.artifact_caching_proxy: false`
      'jenkinscontroller/casc/artifact-caching-proxy.yaml.erb',
      # Opt-in with `profile::jenkinscontroller::jcasc.unclassified.data
      'jenkinscontroller/casc/unclassified.yaml.erb',
      # Opt-in with `profile::jenkinscontroller::jcasc.artifact-manager.data
      'jenkinscontroller/casc/artifact-manager.yaml.erb',
      # Opt-in with `profile::jenkinscontroller::jcasc.datadog
      'jenkinscontroller/casc/datadog.yaml.erb',
    ],
    config_dir => 'casc.d', # Relative to the jenkins_home
  }

  $jcasc_final_config = $jcasc_default_config + $jcasc

  if $jcasc_final_config["enabled"] {
    file { "${jenkins_home}/${$jcasc_final_config["config_dir"]}" :
      ensure  => directory,
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0700',
      require => [
        User['jenkins'],
        File[$jenkins_home],
      ],
    }

    # Define Casc directory through java opts to avoid conditional environment variable
    if $jcasc_final_config["reload_token"] != '' {
      $jcasc_java_opts = " -Dcasc.jenkins.config=${container_jenkins_home}/${$jcasc_final_config["config_dir"]} \
        -Dcasc.reload.token=${$jcasc_final_config["reload_token"]}"
    } else {
      $jcasc_java_opts = " -Dcasc.jenkins.config=${container_jenkins_home}/${$jcasc_final_config["config_dir"]}"
    }

    # The array $jcasc_final_config["common_configs"] contains the JCasC configurations which are consistents
    #   across our Jenkins controllers. You can override the variable in hieradata to opt-out?
    # The array $jcasc_final_config["custom_configs"] contains the JCasC configurations provided through hieradata (e.g. per-controller)
    $all_jcasc_configs = concat($jcasc_final_config["common_configs"], $jcasc_final_config["custom_configs"])

    # Applies CasC files from hieradata's definition (templates to be rendered as yaml files)
    $all_jcasc_configs.each | $jcasc_config_source_file | {
      $jcasc_config_file = basename($jcasc_config_source_file, '.erb')

      file { "${jenkins_home}/${$jcasc_final_config["config_dir"]}/${jcasc_config_file}":
        ensure  => file,
        owner   => 'jenkins',
        group   => 'jenkins',
        content => template("${module_name}/${jcasc_config_source_file}"),
        require => [
          User['jenkins'],
          File["${jenkins_home}/${$jcasc_final_config["config_dir"]}"],
        ],
        before  => Docker::Run[$docker_container_name],
        notify  => Exec['perform-jcasc-reload'],
      }
    }

    exec { 'perform-jcasc-reload':
      command     => "/usr/bin/curl -XPOST --silent --show-error http://127.0.0.1:8080/reload-configuration-as-code/?casc-reload-token=${$jcasc_final_config["reload_token"]}",
      #   # Retry for 300s: jenkins might be restarting
      tries       => 30,
      try_sleep   => 10,
      refreshonly => true,
      logoutput   => true,
    }
  } else {
    $jcasc_java_opts = ''
  }

  ##############################################################################

  docker::run { $docker_container_name:
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
      "HOME=${container_jenkins_home}",
      'USER=jenkins',
      "JAVA_OPTS=${java_opts}${jcasc_java_opts}",
      'JENKINS_OPTS=--httpKeepAliveTimeout=60000',
      'LANG=C.UTF-8', # For context, cfr https://github.com/jenkinsci/docker/pull/1194
    ],
    ports            => ['8080:8080', '50000:50000'],
    volumes          => ["${jenkins_home}:/var/jenkins_home"],
    pull_on_start    => true,
    require          => [
      File[$jenkins_home],
      User['jenkins'],
    ],
  }

  # CLI support: legacy support (ensure clean up of old resources)
  ##############################################################################
  exec { 'safe-restart-jenkins':
    command     => "/usr/bin/docker restart ${docker_container_name}",
    refreshonly => true,
  }
  ##############################################################################

  profile::jenkinsplugin { $plugins:
    # Only install plugins after we've secured Jenkins, that seems reasonable
    require => [
      File[$groovy_d],
    ],
  }

  file { [$apache_log_dir, $docroot]:
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

  $ci_fqdn_x_forwarded_host = "
RequestHeader set X-Forwarded-Host \"${ci_fqdn}\"
"

  $base_custom_fragment = "
RequestHeader set X-Forwarded-Proto \"https\"
RequestHeader set X-Forwarded-Port \"${proxy_port}\"

RewriteEngine on

# Abusive Chinese bot that ignores robots.txt
RewriteCond %{HTTP_USER_AGENT}  Sogou [NC]
RewriteRule \".?\" \"-\" [F]

# Black hole all traffic to routes like /view/All/people/ which is pretty much
# hit illegitimately used anyways
# See thread dump here: https://gist.github.com/rtyler/f8d02e0c5ff11e03da4e331a0f2ca280
RewriteCond %{REQUEST_FILENAME} ^(.*)people(.*)$ [NC]
RewriteRule ^.* \"https://jenkins.io/infra/ci-redirects/\"  [L]

# Loading our Proxy rules ourselves from a custom fragment since the
# puppetlabs/apache module doesn't support ordering of both proxy_pass and
# proxy_pass_match configurations
ProxyRequests Off
ProxyPreserveHost On
ProxyPass / http://localhost:8080/ nocanon
ProxyPassReverse / http://localhost:8080/
"
  if $block_remote_access_api {
    $custom_fragment_api_paths = "
RewriteCond %{REQUEST_FILENAME} ^(.*)api/xml(.*)$ [NC]
RewriteRule ^.* \"https://jenkins.io/infra/ci-redirects/\"  [L]

# Send unauthenticated api/json or api/python requests to `empty.json` to prevent abusive clients
# (checkman) from receiving an invalid JSON response and repeatedly attempting
# to hammer us to get a better response. Works for Python API as well.
RewriteCond \"%{HTTP:Authorization}\" !^Basic
RewriteRule (.*)/api/(json|python)(/|$)(.*) /empty.json
# Analogously for XML.
RewriteCond \"%{HTTP:Authorization}\" !^Basic
RewriteRule (.*)/api/xml(/|$)(.*) /empty.xml
"
  } else {
    $custom_fragment_api_paths = ''
  }

  apache::vhost { $ci_fqdn:
    servername                   => $ci_fqdn,
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    require                      => [
      Docker::Run[$docker_container_name],
      File[$docroot],
      # We need our installation to be secure before we allow access
      File[$groovy_d],
    ],
    port                         => 443,
    override                     => ['All'],
    ssl                          => true,
    docroot                      => $docroot,

    access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir}/access.log.%Y%m%d%H%M%S 86400",
    error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir}/error.log.%Y%m%d%H%M%S 86400",
    proxy_preserve_host          => true,
    allow_encoded_slashes        => 'on',
    custom_fragment              => "${ci_fqdn_x_forwarded_host}
${base_custom_fragment}
${custom_fragment_api_paths}
",
  }

  apache::vhost { "${ci_fqdn} unsecured":
    servername                   => $ci_fqdn,
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    port                         => 80,
    docroot                      => $docroot,
    redirect_status              => 'permanent',
    redirect_dest                => "https://${ci_fqdn}/",
    error_log_file               => "${ci_fqdn}/error_unsecured.log",
    access_log_pipe              => '/dev/null',
    require                      => Apache::Vhost[$ci_fqdn],
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

  # If a custom resource "assets" domain is set (to serve static resources)
  if ($ci_resource_domain != '') {
    $ci_resource_domain_x_forwarded_host = "
RequestHeader set X-Forwarded-Host \"${ci_resource_domain}\"
"
    $apache_log_dir_assets = "/var/log/apache2/${ci_resource_domain}"

    file { $apache_log_dir_assets:
      ensure  => directory,
      require => Package['httpd'],
    }

    apache::vhost { "${ci_resource_domain} unsecured":
      servername                   => $ci_resource_domain,
      port                         => 80,
      use_servername_for_filenames => true,
      use_port_for_filenames       => true,
      docroot                      => $docroot,
      redirect_status              => 'permanent',
      redirect_dest                => "https://${ci_resource_domain}/",
      error_log_file               => "${ci_resource_domain}/error_unsecured.log",
      access_log_pipe              => '/dev/null',
      require                      => Apache::Vhost[$ci_resource_domain],
    }

    apache::vhost { $ci_resource_domain:
      servername                   => $ci_resource_domain,
      require                      => [
        Docker::Run[$docker_container_name],
        File[$docroot],
        # We need our installation to be secure before we allow access
        File[$groovy_d],
      ],
      use_servername_for_filenames => true,
      use_port_for_filenames       => true,
      port                         => 443,
      override                     => ['All'],
      ssl                          => true,
      docroot                      => $docroot,

      access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir}/access.log.%Y%m%d%H%M%S 86400",
      error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir}/error.log.%Y%m%d%H%M%S 86400",
      proxy_preserve_host          => true,
      allow_encoded_slashes        => 'on',
      custom_fragment              => "${ci_resource_domain_x_forwarded_host}
${base_custom_fragment}
${custom_fragment_api_paths}
",
    }
  }

  # Obtain Let's Encrypt certificate(s) and set them up in Apache if in production (e.g. not in vagrant local test)
  if ($letsencrypt == true) and ($environment == 'production') {
    $letsencrypt_plugin = lookup('profile::letsencrypt::plugin')

    case $letsencrypt_plugin {
      'dns-azure': {
        $letsencrypt_custom_plugin = true
      }
      default: {
        $letsencrypt_custom_plugin = false
      }
    }

    # Request a multi-domain certificate (uses Subject Alternate Name)
    letsencrypt::certonly { $ci_fqdn:
      domains       => [$ci_fqdn],
      plugin        => $letsencrypt_plugin,
      custom_plugin => $letsencrypt_custom_plugin,
      manage_cron   => false,
    }

    Apache::Vhost <| title == $ci_fqdn |> {
      ssl_key       => "/etc/letsencrypt/live/${ci_fqdn}/privkey.pem",
      ssl_cert      => "/etc/letsencrypt/live/${ci_fqdn}/fullchain.pem",
    }

    if ($ci_resource_domain != '') {
      letsencrypt::certonly { $ci_resource_domain:
        domains       => [$ci_resource_domain],
        plugin        => $letsencrypt_plugin,
        custom_plugin => $letsencrypt_custom_plugin,
      }

      Apache::Vhost <| title == $ci_resource_domain |> {
        ssl_key       => "/etc/letsencrypt/live/${ci_resource_domain}/privkey.pem",
        ssl_cert      => "/etc/letsencrypt/live/${ci_resource_domain}/fullchain.pem",
      }
    }
  }
}
