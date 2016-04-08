#
# Basic profile included in each node
class profile::base {

  include profile::accounts

  if $::kernel == 'Linux' {
    include profile::apt
    # None of these modules support anything other than Linux (apparently)
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
}
