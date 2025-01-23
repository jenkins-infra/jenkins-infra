#
# This profile configures letsencrypt on the host it's applied to
class profile::letsencrypt (
  String $plugin = '',
  Hash $dns_azure = {},
  # TODO: track with updatecli
  String $certbot_version = '3.1.0',
  # TODO: track with updatecli
  String $certbot_dnsazure_version = '2.6.1',
  Stdlib::Absolutepath $certbot_bin = '/usr/local/bin/certbot'
) {
  # Snap package can't be installed in a container so we use the pip installation for certbot.

  # Custom crontab to control the renew command (absolute path, logging to var log, etc.)
  # Package 'crontab' already installed here
  cron { 'certbot-renew-all':
    command => "bash -c 'date && ${certbot_bin} renew' >>/var/log/certbot-renew-all.log 2>&1",
    user    => 'root',
    hour    => 6,
    minute  => 0,
  }

  case $facts['os']['distro']['codename'] {
    'bionic': {
      $python_certbot_version = '3.8'
      $python_system_version = '3.6' # Required to be the default to avoid breaking apt
      $certbot_pip_version = '' # 3.0.x is the latest certbot version supporting Python < 3.10
      $certbot_pip_version_check = '' # Only check for the pip presence
    }
    'focal': {
      $python_certbot_version = '3.8'
      $python_system_version = '3.8' # Required to be the default to avoid breaking apt
      $certbot_pip_version = '' # 3.0.x is the latest certbot version supporting Python < 3.10
      $certbot_pip_version_check = '' # Only check for the pip presence
    }
    'jammy':  {
      $python_certbot_version = '3.10'
      $python_system_version = '3.10' # Required to be the default to avoid breaking apt
      $certbot_pip_version = "==${certbot_version}"
      $certbot_pip_version_check = "| /bin/grep ${certbot_version}"
    }
    default: {
      fail('[profile::letsencrypt] Unsupported Ubuntu distribution.')
    }
  }
  $python_weight       = regsubst($python_certbot_version, '\.','')

  ['python3', 'python3-pip', "python${python_certbot_version}", 'libaugeas0'].each | $package_name | {
    package { $package_name:
      ensure => 'installed',
    }
  }

  exec { 'Ensure pip is initialized for certbot':
    require => [Package["python${python_certbot_version}"],Package['python3-pip']],
    command => "/usr/bin/python${python_certbot_version} -m pip install --upgrade pip",
    unless  => "/usr/bin/python${python_certbot_version} -m pip list --outdated | /bin/grep --invert-match --word-regexp pip",
  }

  exec { 'Install certbot':
    require => [Package["python${python_certbot_version}"],Package['python3-pip'], Exec['Ensure pip is initialized for certbot']],
    command => "/usr/bin/python${python_certbot_version} -m pip install --upgrade certbot${certbot_pip_version}",
    unless  => "/usr/bin/python${python_certbot_version} -m pip list | /bin/grep --word-regexp certbot ${certbot_pip_version_check}",
  }

  exec { 'Install certbot-apache plugin':
    require => Exec['Install certbot'],
    command => "/usr/bin/python${python_certbot_version} -m pip install --upgrade --use-pep517 certbot-apache${certbot_pip_version}",
    unless  => "/usr/bin/python${python_certbot_version} -m pip list | /bin/grep --word-regexp certbot-apache ${certbot_pip_version_check}",
  }

  exec { 'Install certbot-dns-azure plugin':
    require => Exec['Install certbot'],
    command => "/usr/bin/python${python_certbot_version} -m pip install --upgrade certbot-dns-azure==${certbot_dnsazure_version}",
    unless  => "/usr/bin/python${python_certbot_version} -m pip list | /bin/grep --word-regexp certbot-dns-azure | /bin/grep ${certbot_dnsazure_version}",
  }

  $default_config = {
    email  => lookup('letsencrypt::config::email'),
    server => lookup('letsencrypt::config::server'),
  }

  if $plugin == 'apache' {
    # Case of HTTP-01 challenge
    $_additional_config = {
      'authenticator'        => 'apache',
      'preferred-challenges' => 'http',
      'deploy-hook'          => 'systemctl reload apache2',
    }

    file { '/etc/letsencrypt/azure.ini':
      ensure  => 'absent',
    }
  }

  if $plugin == 'dns-azure' {
    # Case of DNS-01 challenge (with Azure DNS)
    $_additional_config = {
      'authenticator'        => 'dns-azure',
      'preferred-challenges' => 'dns',
      'dns-azure-config'     => '/etc/letsencrypt/azure.ini',
      'deploy-hook'          => 'systemctl reload apache2',
    }

    file { '/etc/letsencrypt/azure.ini':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => template("${module_name}/letsencrypt/azure.ini.erb"),
    }
  }

  $final_config = $default_config + $_additional_config

  class { 'letsencrypt':
    config         => $final_config,
    package_ensure => 'absent', # We use pip packages instead of the virtual apt package
    configure_epel => false,
  }
}
