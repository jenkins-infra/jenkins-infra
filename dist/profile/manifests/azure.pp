#
# The Azure profile is for integration a node with Azure tooling. It doesn't
# necessarily indicate that the node is located in Azure
class profile::azure (
  $cli = true,
) {

  if $cli {
    ensure_packages(['python-pip'])

    package { 'azure-cli-python' :
        ensure   => absent,
        name     => 'azure-cli',
        provider => pip,
        require  => Package['python-pip'],
    }

    apt::source { 'azure-cli':
        location => 'https://apt-mo.trafficmanager.net/repos/azure-cli/',
        release  => 'wheezy',
        repos    => 'main',
        key      => {
        server => 'apt-mo.trafficmanager.net',
        id     => '417A0893',
        },
    }

    package { 'azure-cli':
        ensure  => present,
        require => Apt::Source['azure-cli'],
    }
  }
}
