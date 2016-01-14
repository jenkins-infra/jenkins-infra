#
# Basic profile included in each node
class profile::base {
  include profile::accounts
  include profile::apt
  include profile::firewall
  include profile::ntp
  include profile::sudo
  include profile::diagnostics

  class { 'ssh::server':
    storeconfigs_enabled => false,
    options              => {
      'PasswordAuthentication' => 'no',
      'PubkeyAuthentication'   => 'yes',
    },
  }

  class { 'ssh::client':
    options => {
      'UseRoaming' => 'no',
    },
  }
}
