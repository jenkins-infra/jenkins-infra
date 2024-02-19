# Profile to ensure `azcopy` is installed, up-to-date and set up (SAS token generation, etc.)
class profile::azcopy (
  String $version,
  String $install_dir = '/usr/local/bin',
) {
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

  if $version {
    $azcopysemver = split($version, /-/)[0]
    $azcopy_url = "https://azcopyvnext.azureedge.net/releases/release-${version}/azcopy_linux_${architecture}_${azcopysemver}.tar.gz"

    exec { 'Install azcopy':
      require => [Package['curl'], Package['tar']],
      command => "/usr/bin/curl --location ${azcopy_url} | /bin/tar --extract --gzip --strip-components=1 --directory=${install_dir}/ --wildcards '*/azcopy' && chmod a+x ${install_dir}/azcopy",
      unless  => "/usr/bin/test -f ${install_dir}/azcopy && ${install_dir}/azcopy --version | /bin/grep --quiet ${azcopysemver}",
    }
  }
}
