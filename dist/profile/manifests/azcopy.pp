# Profile to ensure `azcopy` and `az-cli` are installed, up-to-date and set up (SAS token generation, etc.)
class profile::azcopy (
  String $azcopy_version,
  String $az_cli_version,
  String $install_dir   = '/usr/local/bin',
) {
  include apt
  # There is no linux_aarch64 azcopy release, considering that aarch64 = arm64 so vagrant can run on Mac Silicon
  $architecture = $facts['os']['architecture'] ? {
    'aarch64' => 'arm64',
    default   => $facts['os']['architecture'],
  }

  # Dependencies used to install azcopy
  ensure_packages([
      'curl',
      'tar',
  ])

  if $azcopy_version {
    $msprodpackagepath = '/tmp/microsoft-prod.deb'
    file { $msprodpackagepath:
      ensure => 'file',
      source => "https://packages.microsoft.com/config/${facts['os']['name'].downcase()}/${facts['os']['release']['full']}/packages-microsoft-prod.deb",
    }

    package { 'microsoftprod':
      ensure   => present,
      source   => $msprodpackagepath,
      provider => dpkg,
      require  => File[$msprodpackagepath],
    }

    package { 'azcopy':
      ensure  => $azcopy_version,
      require => [Class['apt::update'], Package['microsoftprod']],
    }
  }

  if $az_cli_version {
    apt::source { 'microsoft':
      comment  => 'microsoft',
      location => 'https://packages.microsoft.com/repos/azure-cli/',
      repos    => 'main',
      key      => {
        # id retrieved by running "gpg microsoft.asc"
        id     => 'BC528686B50D79E339D3721CEB3E94ADBE1229CF',
        name   => 'microsoft.asc',
        source => 'https://packages.microsoft.com/keys/microsoft.asc',
      },
    }

    package { 'azure-cli':
      # azure-cli package have additional suffixes to their semver version like "<az_cli_version>-1~bionic"
      ensure  => "${az_cli_version}-1~${facts['os']['distro']['codename']}",
      require => Class['apt::update'],
    }

    file { '/usr/local/bin/get-fileshare-signed-url.sh':
      ensure => file,
      mode   => '0755',
      source => "puppet:///modules/${module_name}/azcopy/get-fileshare-signed-url.sh",
    }
  }
}
