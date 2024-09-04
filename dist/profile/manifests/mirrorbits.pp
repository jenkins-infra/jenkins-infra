# Profile to ensure `mirrorbits` CLI is installed
class profile::mirrorbits (
  String $mirrorbits_version,
  String $install_dir   = '/usr/local/bin',
) {
  # Only x86_64 is currently supported out of the box - https://github.com/etix/mirrorbits/issues/150
  # If arm64 CLI is needed, extract it from https://github.com/jenkins-infra/docker-mirrorbits built container images

  # Dependencies used to install mirrorbits CLI
  include apt
  ensure_packages([
      'curl',
      'tar',
  ])

  if $mirrorbits_version {
    $mirrorbits_url = "https://github.com/etix/mirrorbits/releases/download/${mirrorbits_version}/mirrorbits-${mirrorbits_version}.tar.gz"

    exec { 'Install mirrorbits CLI':
      require => [Package['curl'], Package['tar']],
      command => "/usr/bin/curl --location ${mirrorbits_url} | /bin/tar --extract --gzip --strip-components=1 --directory=${install_dir}/ mirrorbits/mirrorbits && chmod a+x ${install_dir}/mirrorbits",
      unless  => "/usr/bin/test -f ${install_dir}/mirrorbits && { ${install_dir}/mirrorbits version || true; } 2>/dev/null | /bin/grep --quiet ${mirrorbits_version}",
    }
  }
}
