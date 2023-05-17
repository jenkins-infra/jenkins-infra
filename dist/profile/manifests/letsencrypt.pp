#
# This profile configures letsencrypt on the host it's applied to
class profile::letsencrypt (
  String $plugin  = '',
  Hash $dns_azure = {},
) {
  # Snap package is broken (despite being really helpfull) until https://github.com/terrycain/certbot-dns-azure/issues/28 is fixed
  # So let's use Python (3.8 required) with pinned (and old) versions for both certbot and certbot azure-dns plugin

  ## Ensure that any pre-existing snap and/or apt installation of certbot are removed
  include snap
  ['certbot', 'certbot-dns-azure'].each | $snap_package | {
    package { $snap_package:
      ensure   => 'absent',
      provider => 'snap',
    }
  }
  file { '/snap/bin/certbot':
    ensure => 'absent',
  }

  case $facts['os']['distro']['codename'] {
    'bionic': {
      $python_certbot_version = '3.8'
      $python_system_version = '3.6' # Required to be the default to avoid breaking apt
    }
    'focal': {
      $python_certbot_version = '3.8'
      $python_system_version = '3.8' # Required to be the default to avoid breaking apt
    }
    'jammy':  {
      $python_certbot_version = '3.10'
      $python_system_version = '3.10' # Required to be the default to avoid breaking apt
    }
    default: {
      fail('[profile::letsencrypt] Unsupported Ubuntu distribution.')
    }
  }
  $python_weight       = regsubst($python_certbot_version, '\.','')
  $certbot_version     = '1.32.0'

  ['python3', 'python3-pip', "python${python_certbot_version}", 'libaugeas0'].each | $package_name | {
    package { $package_name:
      ensure => 'installed',
    }
  }

  exec { 'Ensure pip is initialized for certbot':
    require => [Package["python${python_certbot_version}"],Package['python3-pip']],
    command => "/usr/bin/python${python_certbot_version} -m pip install --upgrade pip setuptools setuptools-rust",
    unless  => "/usr/bin/python${python_certbot_version} -m pip list --format=json | /bin/grep --quiet setuptools-rust",
  }

  exec { 'Install certbot':
    require => [Package["python${python_certbot_version}"],Package['python3-pip'], Exec['Ensure pip is initialized for certbot']],
    command => "/usr/bin/python${python_certbot_version} -m pip install --upgrade pyopenssl certbot==${certbot_version} acme==${certbot_version}",
    creates => '/usr/local/bin/certbot',
  }

  $default_config = {
    email  => lookup('letsencrypt::config::email'),
    server => lookup('letsencrypt::config::server'),
  }

  if $plugin == 'apache' {
    exec { 'Install certbot-apache plugin':
      require => Exec['Install certbot'],
      command => "/usr/bin/python${python_certbot_version} -m pip install --upgrade certbot-apache==${certbot_version}",
      unless  => '/usr/local/bin/certbot plugins --text 2>&1 | /bin/grep --quiet apache',
    }

    # Case of HTTP-01 challenge
    $_additional_config = {
      'authenticator'        => 'apache',
      'preferred-challenges' => 'http',
    }

    file { '/etc/letsencrypt/azure.ini':
      ensure  => 'absent',
    }
  }

  if $plugin == 'dns-azure' {
    exec { 'Install certbot-dns-azure plugin':
      require => Exec['Install certbot'],
      command => "/usr/bin/python${python_certbot_version} -m pip install --upgrade certbot-dns-azure",
      unless  => '/usr/local/bin/certbot plugins --text 2>&1 | /bin/grep --quiet dns-azure',
    }

    # Case of DNS-01 challenge (with Azure DNS)
    $_additional_config = {
      'authenticator'        => 'dns-azure',
      'preferred-challenges' => 'dns',
      'dns-azure-config'     => '/etc/letsencrypt/azure.ini',
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
    package_ensure => 'absent', # We use snap or pip packages instead of the virtual apt package
    configure_epel => false,
  }
}
