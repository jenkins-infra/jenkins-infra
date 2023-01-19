#
# This profile configures letsencrypt on the host it's applied to
class profile::letsencrypt (
  Hash $dns_azure                  = {},
) {
  # Use snap package for certbot: safer packaging and maintained certbot version
  # Ref. https://github.com/voxpupuli/puppet-letsencrypt/pull/298
  include snap

  package { 'certbot':
    ensure          => 'installed',
    provider        => 'snap',
    install_options => ['classic'],
  }

  file { '/usr/bin/certbot':
    ensure  => 'link',
    source  => '/snap/bin/certbot',
    require => Package['certbot'],
  }

  $default_config = {
    email  => lookup('letsencrypt::config::email'),
    server => lookup('letsencrypt::config::server'),
  }

  if $dns_azure == {} {
    # Case of HTTP-01 challenge
    $_additional_config = {}

    package { 'certbot-dns-azure':
      ensure   => 'absent',
      provider => 'snap',
    }

    file { '/etc/letsencrypt/azure.ini':
      ensure  => 'absent',
    }
  } else {
    # Case of DNS-01 challenge (with Azure DNS)
    $_additional_config = {
      'authenticator'          => 'dns-azure',
      'preferred-challenges' => 'dns',
      'dns-azure-config'     => '/etc/letsencrypt/azure.ini',
    }

    package { 'certbot-dns-azure':
      ensure          => 'installed',
      provider        => 'snap',
      install_options => ['channel=edge'],
      require         => Package['certbot'],
    }

    snap_conf { 'trust plugin with root dns-azure':
      ensure => present,
      conf   => 'trust-plugin-with-root',
      value  => 'ok',
      snap   => 'certbot',
    }

    exec { 'Connect certbot with certbot-dns-azure plugin':
      command => '/usr/bin/snap connect certbot:plugin certbot-dns-azure',
      unless  => '/snap/bin/certbot plugins --text | /bin/grep "dns-azure" 2>/dev/null',
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
    package_ensure => 'absent', # We use snap package instead
    configure_epel => false,
  }
}
