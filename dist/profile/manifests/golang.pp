#
# Profile to provision the necessary golang environment
#
class profile::golang (
  String $golang_version,
) {
  $architecture = $facts['os']['architecture'] ? {
    'aarch64' => 'arm64',
    default   => $facts['os']['architecture'],
  }
  $golang_dl_url="https://go.dev/dl/go${golang_version}.linux-${architecture}.tar.gz"
  $golang_dl_archive="/tmp/go${golang_version}.linux-${architecture}.tar.gz"
  $golang_installation_prefix='/usr/local'

  exec { "Install golang version ${golang_version}":
    command => "/usr/bin/curl --silent --location --verbose --show-error --output ${golang_dl_archive} \"${golang_dl_url}\" && /usr/bin/rm -rf ${golang_installation_prefix}/go && /usr/bin/tar -C ${golang_installation_prefix} -xzf ${golang_dl_archive} && /usr/bin/rm -f ${golang_dl_archive} && ln -s ${golang_installation_prefix}/go/bin/go /usr/local/bin/go",
    unless  => "/usr/bin/test -f /usr/local/bin/go && /usr/local/bin/go version 2>/dev/null | /bin/grep ${golang_version}",
  }
}
