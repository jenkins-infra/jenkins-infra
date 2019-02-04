#
# The Azure profile is for integration a node with Azure tooling. It doesn't
# necessarily indicate that the node is located in Azure
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt
class profile::azure (
  $cli = true,
) {

  if $cli {
    ensure_packages(['python-pip'])

    package { 'azure-cli-python' :
        ensure   => absent,
        provider => pip,
        require  => Package['python-pip'],
    }

    apt::source { 'azure-cli':
        architecture => 'amd64',
        location     => 'https://packages.microsoft.com/repos/azure-cli/',
        repos        => 'main',
        key          => {
          server => 'packages.microsoft.com',
          id     => 'BC528686B50D79E339D3721CEB3E94ADBE1229CF',
        },
    }

    package { 'azure-cli':
        ensure  => present,
        require => Apt::Source['azure-cli'],
    }

    package { 'blobxfer' :
        ensure   => present,
        provider => pip,
  }
}
