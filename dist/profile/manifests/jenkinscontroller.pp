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
  Boolean $authenticated_access                = false,
  Boolean $embeddable_build_status             = false,
  Array $admin_ldap_groups                     = [],
  Array $admin_users                           = [],
  Stdlib::Fqdn $ci_fqdn                        = '',
  Hash $additional_fqdns                       = {},
  String $ci_resource_domain                   = '',
  String $docker_image                         = 'jenkins/jenkins',
  String $docker_tag                           = 'lts-jdk25',
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
  Hash $datadog                                = {
    metrics_collection_port => 8125,
    traces_collection_port  => 8126,
    logs_collection_port    => 8127,
  },
  Boolean $block_remote_access_api             = false,
  Hash $tools_versions                         = {},
  Array $kubeconfigs                           = [],
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
-Dorg.jenkinsci.plugins.workflow.steps.durable_task.DurableTaskStep.USE_WATCHING=true",
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

  $all_fqdns = ($additional_fqdns.keys() << $ci_fqdn )
  $apache_log_dirs = $all_fqdns.map |$fqdn| { "/var/log/apache2/${fqdn}" }

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

  file { '/etc/profile.d/prompt.sh':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/jenkinscontroller/prompt.sh.erb"),
  }

  ##############################################################################
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
  # JCasc Files: if provided through hieradata, then add these files in the ${jenkins_home}/casc.d/
  ##############################################################################
  $jcasc_default_config= {
    enabled => false, # Disabled by default to avoid messing up with unmanaged instances
    custom_configs => [],
    reload_token => '',
    # Default JCasc templates shared by all Jenkins controllers.
    # Use hieradata attribute to opt-out (see below), or override with an additional file (lexicographic).
    common_configs => [
      ## Opt-out of all agent clouds with `profile::jenkinscontroller::jcasc.cloud_agents.disabled: true` or `profile::jenkinscontroller::jcasc.cloud_agents: {}`
      # Opt-out of all agent clouds with `profile::jenkinscontroller::jcasc.cloud_agents.azure_vm_agents.disabled: true` or `profile::jenkinscontroller::jcasc.cloud_agents.azure_vm_agents: {}`
      'jenkinscontroller/casc/clouds-azurevm.yaml.erb',
      # Opt-out of all agent clouds with `profile::jenkinscontroller::jcasc.cloud_agents.ec2.disabled: true` or `profile::jenkinscontroller::jcasc.cloud_agents.ec2: {}`
      'jenkinscontroller/casc/clouds-ec2.yaml.erb',
      # Opt-out of all agent clouds with `profile::jenkinscontroller::jcasc.cloud_agents.kubernetes.disabled: true` or `profile::jenkinscontroller::jcasc.cloud_agents.kubernetes: {}`
      'jenkinscontroller/casc/clouds-kubernetes.yaml.erb',
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
      # Opt-in with `profile::jenkinscontroller::jcasc.datadog
      'jenkinscontroller/casc/datadog.yaml.erb',
      # Opt-in with `profile::jenkinscontroller::jcasc.artifacts_manager
      'jenkinscontroller/casc/artifacts-manager.yaml.erb',
      # Opt-in with `profile::jenkinscontroller::jcasc.appearance
      'jenkinscontroller/casc/appearance.yaml.erb',
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

    $perform_jcasc_reload_cmd = "/usr/bin/curl -XPOST --silent --show-error http://127.0.0.1:8080/reload-configuration-as-code/?casc-reload-token=${$jcasc_final_config["reload_token"]}"
  } else {
    $jcasc_java_opts = ''
    $perform_jcasc_reload_cmd = 'echo "No JCasC configuration defined"'
  }

  exec { 'perform-jcasc-reload':
    command     => $perform_jcasc_reload_cmd,
    # Jenkins might be restarting
    tries       => 3,
    try_sleep   => 10,
    refreshonly => true,
    logoutput   => true,
    require     => Docker::Run[$docker_container_name],
  }

  if $jcasc_final_config['datadog'] {
    firewall { '901 accept datadog local metrics collection':
      proto   => 'udp',
      dport   => $datadog['metrics_collection_port'],
      iniface => ['! lo', '! docker0'],
      action  => 'reject',
    }

    firewall { '902 accept datadog local trace collection':
      proto   => 'tcp',
      dport   => $datadog['traces_collection_port'],
      iniface => 'docker0',
      action  => 'accept',
    }

    if $jcasc_final_config['datadog']['collectBuildLogs'] {
      firewall { '905 accept datadog local jenkins logs collection':
        proto   => 'tcp',
        dport   => $datadog['logs_collection_port'],
        iniface => 'docker0',
        action  => 'accept',
      }

      file { "${datadog_agent::params::conf_dir}/jenkins.d":
        ensure  => directory,
        owner   => $datadog_agent::params::dd_user,
        group   => $datadog_agent::params::dd_group,
        mode    => '0755',
        require => Class['datadog_agent'],
      }
      file { "${datadog_agent::params::conf_dir}/jenkins.d/conf.yaml":
        ensure  => file,
        owner   => $datadog_agent::params::dd_user,
        group   => $datadog_agent::params::dd_group,
        mode    => '0644',
        require => File["${datadog_agent::params::conf_dir}/jenkins.d"],
        content => template("${module_name}/jenkinscontroller/datadog_jenkins_conf.yaml.erb"),
        notify  => Service['datadog-agent'],
      }
    }
  }

  ##############################################################################
  # Install 'awscli' INSIDE the controller is specified
  # Use cases:
  # - Kubernetes plugin with EC2 Instance profile authentication
  $awscli_version = lookup({ 'name' => 'profile::awscli::version', 'default_value' => '' })
  $container_base_path = '/opt/java/openjdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  if $awscli_version != '' {
    include profile::awscli
    $awscli_install_dir = lookup({ 'name' => 'profile::awscli::install_dir', 'default_value' => '/var/awscli' })
    $awscli_container_volume = "${awscli_install_dir}:${awscli_install_dir}:ro"
    $final_container_path = "${awscli_install_dir}/v2/current/bin:${container_base_path}"
  } else {
    $awscli_container_volume = ''
    $final_container_path = $container_base_path
  }

  $kubeconfig_path = '/var/jenkins_kubeconfigs'
  if $kubeconfigs and $kubeconfigs.size > 0 {
    file { $kubeconfig_path:
      ensure  => directory,
    }
    $kubeconfigs.each | $kconfig | {
      $kconfig_file = "${kubeconfig_path}/${kconfig['cluster_name']}.yml"

      file { $kconfig_file:
        ensure  => file,
        require => [File[$kubeconfig_path]],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template("${module_name}/jenkinscontroller/kubeconfig.erb"),
      }
    }
    $kubeconfig_container_volume = "${kubeconfig_path}:${kubeconfig_path}:ro"
    $kubeconfig_envvar_value = "KUBECONFIG=${kubeconfig_path}/${kubeconfigs[0]['cluster_name']}.yml"
  } else {
    file { $kubeconfig_path:
      ensure => absent,
      force  => true,
    }
    $kubeconfig_container_volume = ''
    $kubeconfig_envvar_value = ''
  }

  docker::run { $docker_container_name:
    memory_limit     => $memory_limit,
    image            => "${docker_image}:${docker_tag}",
    # TODO: cleanup after UC move to Azure + Cloudflare (remove the add-host)
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
      "PATH=${final_container_path}",
      $kubeconfig_envvar_value,
    ].filter |$item| { $item != '' },
    ports            => ['8080:8080', '50000:50000'],
    volumes          => concat([
      "${jenkins_home}:/var/jenkins_home:rw"],
      $awscli_container_volume,
      $kubeconfig_container_volume,
    ).filter |$item| { $item != '' },
    pull_on_start    => true,
    require          => [
      File[$jenkins_home],
      User['jenkins'],
    ],
  }

  # Add specific plugins if the JCasC configuration need them, even if not specified
  $known_plugins_configs = {
    'artifact-manager-s3' => 'artifacts_manager',
    'azure-vm-agents' => 'cloud_agents.azure_vm_agents',
    'config-file-provider' => 'artifact_caching_proxy',
    'configuration-as-code' => 'enabled',
    'datadog' => 'datadog',
    'ec2' => 'cloud_agents.ec2',
    'kubernetes' => 'cloud_agents.kubernetes',
    'pipeline-graph-view' => 'appearance.pipeline_graph_view',
    'ssh-slaves' => 'permanent_agents',
    'toolenv' => 'tools.generic',
    'workflow-aggregator' => 'global_libraries',
  }

  # Auto-detect plugins by checking the known JCasC directives in the resolved hieradata tree
  $autodetected_plugins = $known_plugins_configs.keys.filter |$plugin| {
    $jcasc_final_config.get($known_plugins_configs[$plugin], false)
  }

  # Merge autodetected plugins with user-specified and avoid duplicates
  $all_plugins = ($plugins + $autodetected_plugins).sort.unique

  $all_plugins.each |$plugin| {
    exec { "install-plugin-${plugin}":
      ## Check for plugin presence on the HOST (e.g. with the jenkins home in "/var/lib/jenkins" on the filesystem)
      unless    => "/usr/bin/test -f /var/lib/jenkins/plugins/${plugin}.jpi || /usr/bin/test -f /var/lib/jenkins/plugins/${plugin}.hpi",
      ## Install the plugin (if needed) in the container, e.g. with the jenkins home mounted in /var/jenkins_home
      command   => "docker run -t --entrypoint=jenkins-plugin-cli --env=CACHE_DIR=/tmp --restart=no --volume=${jenkins_home}:/var/jenkins_home:rw --user=$(id -u jenkins):$(id -g jenkins) ${docker_image}:${docker_tag} --plugins ${plugin} --plugin-download-directory /var/jenkins_home/plugins",
      path      => ['/bin', '/usr/bin'],
      notify    => Docker::Run['jenkins'],
      require   => Service['docker'],
      before    => Exec['perform-jcasc-reload'],
      logoutput => true,
      tries     => 3,
      try_sleep => 2,
    }
  }

  ($apache_log_dirs << $docroot).each | $dir | {
    file { $dir:
      ensure  => directory,
      require => Package['httpd'],
    }
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
      File["/var/log/apache2/${ci_fqdn}"],
      # We need our installation to be secure before we allow access
      File[$groovy_d],
    ],
    port                         => 443,
    override                     => ['All'],
    ssl                          => true,
    docroot                      => $docroot,

    access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t /var/log/apache2/${ci_fqdn}/access.log.%Y%m%d%H%M%S 86400",
    error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t /var/log/apache2/${ci_fqdn}/error.log.%Y%m%d%H%M%S 86400",
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

    access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t /var/log/apache2/${ci_fqdn}/access_unsecured.log.%Y%m%d%H%M%S 86400",
    error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t /var/log/apache2/${ci_fqdn}/error_unsecured.log.%Y%m%d%H%M%S 86400",
    require                      => Apache::Vhost[$ci_fqdn],
  }

  # Create additional FQDN vhosts (aliases, legacy hostnames, etc.)
  $additional_fqdns.keys().each | $fqdn | {
    if $additional_fqdns[$fqdn].get('isalias', false) {
      apache::vhost { $fqdn:
        servername                   => $fqdn,
        use_servername_for_filenames => true,
        use_port_for_filenames       => true,
        require                      => [
          Apache::Vhost[$ci_fqdn],
          File[$docroot],
          File["/var/log/apache2/${fqdn}"],
        ],
        port                         => 443,
        override                     => ['All'],
        ssl                          => true,
        docroot                      => $docroot,

        access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t /var/log/apache2/${fqdn}/access.log.%Y%m%d%H%M%S 86400",
        error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t /var/log/apache2/${fqdn}/error.log.%Y%m%d%H%M%S 86400",
        proxy_preserve_host          => true,
        allow_encoded_slashes        => 'on',
        custom_fragment              => "
RequestHeader set X-Forwarded-Host \"${fqdn}\"
${base_custom_fragment}
${custom_fragment_api_paths}
",
      }
    } else {
      apache::vhost { $fqdn:
        servername                   => $fqdn,
        use_servername_for_filenames => true,
        use_port_for_filenames       => true,
        require                      => [
          Apache::Vhost[$ci_fqdn],
          File[$docroot],
          File["/var/log/apache2/${fqdn}"],
        ],
        port                         => 443,
        ssl                          => true,
        docroot                      => $docroot,
        redirect_status              => 'permanent',
        redirect_dest                => "https://${ci_fqdn}/",

        access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t /var/log/apache2/${fqdn}/access.log.%Y%m%d%H%M%S 86400",
        error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t /var/log/apache2/${fqdn}/error.log.%Y%m%d%H%M%S 86400",
      }
    }

    # Enforced HTTP to HTTPS redirection
    apache::vhost { "${fqdn} unsecured":
      servername                   => $fqdn,
      use_servername_for_filenames => true,
      use_port_for_filenames       => true,
      port                         => 80,
      docroot                      => $docroot,
      redirect_status              => 'permanent',
      redirect_dest                => "https://${fqdn}/",

      access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t /var/log/apache2/${fqdn}/access_unsecured.log.%Y%m%d%H%M%S 86400",
      error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t /var/log/apache2/${fqdn}/error_unsecured.log.%Y%m%d%H%M%S 86400",
      require                      => [
        Apache::Vhost[$fqdn],
        File["/var/log/apache2/${fqdn}"],
      ],
    }
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

      access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir_assets}/access.log.%Y%m%d%H%M%S 86400",
      error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir_assets}/error.log.%Y%m%d%H%M%S 86400",
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

    # Request a multi-domain certificate (uses Subject Alternate Name)
    letsencrypt::certonly { $ci_fqdn:
      domains       => [$ci_fqdn],
      custom_plugin => true,
      manage_cron   => false,
    }

    Apache::Vhost <| title == $ci_fqdn |> {
      ssl_key       => "/etc/letsencrypt/live/${ci_fqdn}/privkey.pem",
      ssl_cert      => "/etc/letsencrypt/live/${ci_fqdn}/fullchain.pem",
    }

    if ($ci_resource_domain != '') {
      letsencrypt::certonly { $ci_resource_domain:
        domains       => [$ci_resource_domain],
        custom_plugin => true,
      }

      Apache::Vhost <| title == $ci_resource_domain |> {
        ssl_key       => "/etc/letsencrypt/live/${ci_resource_domain}/privkey.pem",
        ssl_cert      => "/etc/letsencrypt/live/${ci_resource_domain}/fullchain.pem",
      }
    }

    $additional_fqdns.keys().each | $fqdn | {
      # Request a multi-domain certificate (uses Subject Alternate Name)
      letsencrypt::certonly { $fqdn:
        domains       => [$fqdn],
        custom_plugin => true,
        manage_cron   => false,
      }

      Apache::Vhost <| title == $fqdn |> {
        ssl_key       => "/etc/letsencrypt/live/${fqdn}/privkey.pem",
        ssl_cert      => "/etc/letsencrypt/live/${fqdn}/fullchain.pem",
      }
    }
  }
}
