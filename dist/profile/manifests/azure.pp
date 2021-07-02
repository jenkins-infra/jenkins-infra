#
# The Azure profile is for integration a node with Azure tooling. It doesn't
# necessarily indicate that the node is located in Azure
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt
class profile::azure (
  $cli = true,
) {
  # azure-cli only works on amd64
  if ($cli == true) and ($facts['architecture'] == 'amd64') {

    apt::source { 'azure-cli':
        ensure       =>  present,
        architecture => 'amd64',
        location     => 'https://packages.microsoft.com/repos/azure-cli/',
        repos        => 'main',
        key          => {
          source => 'https://packages.microsoft.com/keys/microsoft.asc',
          id     => 'BC528686B50D79E339D3721CEB3E94ADBE1229CF',
        },
    }

    package { 'azure-cli':
        ensure  => present,
        require => Apt::Source['azure-cli'],
    }
  }
}
