#
# Basic profile included in each node
class profile::base {
  include profile::accounts
  include profile::compliance

  if $::kernel == 'Linux' {
    include profile::apt
    # None of these modules support anything other than Linux (apparently)
    include profile::firewall
    include profile::ntp
    include profile::sudo
    include profile::diagnostics
    include profile::puppetagent
    include profile::rngd

    # Applying the production SSH would break the Vagrant SSH system
    if $::vagrant != '1' {
      include ssh::server
    }
    include ssh::client
  }

  # Collect all our exported host keys, this way we know about every machine
  # properly
  Sshkey <<| 'type' == 'ecdsa-sha2-nistp256' |>>
}
