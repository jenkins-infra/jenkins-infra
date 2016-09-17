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
  include profile::firewall

  if $letsencrypt {
    include profile::letsencrypt
  }

  $ldap_url    = hiera('ldap_url')
  $ldap_dn     = hiera('ldap_dn')
  $ldap_admin_dn = hiera('ldap_admin_dn')
  $ldap_admin_password = hiera('ldap_admin_password')

  class { '::jenkins':
    lts       => true,
  }


  $script_dir = '/usr/share/jenkins'
  exec { 'jenkins-script-mkdirp':
    command => "/bin/mkdir -p ${script_dir}",
    creates => $script_dir,
  }

  $ssh_dir = '/var/lib/jenkins/.ssh'
  $ssh_cli_key = 'jenkins-cli-key'
  exec { 'jenkins-ssh-mkdirp':
    command => "/bin/mkdir -p ${ssh_dir}",
    creates => $ssh_dir,
  }
  exec { 'generate-cli-ssh-key':
    require => Exec['jenkins-ssh-mkdirp'],
    creates => "${ssh_dir}/${ssh_cli_key}",
    command => "/usr/bin/ssh-keygen -b 4096 -q -f ${ssh_dir}/${ssh_cli_key} -N ''",
  }

  $cli_script = "${script_dir}/idempotent-cli"
  file { $cli_script:
    ensure  => present,
    require => Exec['jenkins-script-mkdirp'],
    source  => "puppet:///modules/${module_name}/buildmaster/idempotent-cli",
    mode    => '0755',
  }

  $lockbox_script = "${script_dir}/lockbox.groovy"

  file { $lockbox_script :
    ensure  => present,
    require => Exec['jenkins-script-mkdirp'],
    content =>template("${module_name}/buildmaster/lockbox.groovy.erb"),
  }
  profile::jenkinsgroovy { 'lock-down-jenkins':
    path    => $lockbox_script,
    require => [
      File[$lockbox_script],
      File[$cli_script],
    ],
  }

  profile::jenkinsplugin { $plugins:
    # Only install plugins after we've secured Jenkins, that seems reasonable
    require => [
      File[$cli_script],
      Profile::Jenkinsgroovy['lock-down-jenkins'],
    ],
  }

  file { '/var/lib/jenkins/hudson.plugins.git.GitSCM.xml':
    ensure  => present,
    source  => "puppet:///modules/${module_name}/buildmaster/hudson.plugins.git.GitSCM.xml",
    notify  => Exec['jenkins-reload-config'],
    require => Package['jenkins'],
  }

  exec { 'jenkins-reload-config':
    command     => "${cli_script} reload-configuration",
    refreshonly => true,
    require     => File[$cli_script],
  }

  $docroot = "/var/www/${ci_fqdn}"
  $apache_log_dir = "/var/log/apache2/${ci_fqdn}"

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
