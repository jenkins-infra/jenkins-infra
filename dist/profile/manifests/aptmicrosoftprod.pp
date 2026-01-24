# Profile to ensure `azcopy` and `az-cli` are installed, up-to-date and set up (SAS token generation, etc.)
class profile::aptmicrosoftprod (

) {
  $msprodpackagepath = '/tmp/packages-microsoft-prod.deb'
  file { $msprodpackagepath:
    ensure => 'file',
    source => "https://packages.microsoft.com/config/${facts['os']['name'].downcase()}/${facts['os']['release']['full']}/packages-microsoft-prod.deb",
  }

  package { 'packages-microsoft-prod':
    ensure   => present,
    source   => $msprodpackagepath,
    provider => dpkg,
    require  => File[$msprodpackagepath],
  }
}
