#
# Profile defining the necessary resources to provision our LDAP-based
# accountapp
class profile::accountapp(
  # all injected from hiera
  $image_tag,
  $ldap_url = 'ldap://localhost:389/',
  $ldap_password = '',
  $smtp_server = 'localhost',
  $recaptcha_key = '',
  $app_url = 'https://accounts.jenkins.io/',
) {
  include ::firewall
  include ::profile::docker

  validate_string($image_tag)
  validate_string($ldap_url)
  validate_string($ldap_password)
  validate_string($smtp_server)
  validate_string($recaptcha_key)

  file { '/etc/accountapp' :
    ensure => directory,
    # Don't allow anything not declared in Puppet to be dropped in there
    purge  => true,
  }

  file { '/etc/accountapp/config.properties':
    ensure  => file,
    content => template("${module_name}/accountapp/config.properties.erb"),
    require => File['/etc/accountapp'],
  }

  docker::image { 'jenkinsciinfra/account-app':
    image_tag => $image_tag,
  }

  docker::run { 'account-app':
    command          => undef,
    image            => "jenkinsciinfra/account-app:${image_tag}",
    volumes          => ['/etc/accountapp:/etc/accountapp'],
    require          => File['/etc/accountapp/config.properties'],
    extra_parameters => ['--net=host'],
  }
}
