#
# Export the hostkeys with the specified FQDN
define sshkeyman::hostkey (
) {
  if $facts['ssh']['ecdsa']['key'] {
    @@sshkey { $title:
      ensure => present,
      key    => $facts['ssh']['ecdsa']['key'],
      type   => 'ecdsa-sha2-nistp256',
    }
  }
  elsif $facts['ssh']['rsa']['key'] {
    @@sshkey { $title:
      ensure => present,
      key    => $facts['ssh']['rsa']['key'],
      type   => rsa,
    }
  }
  elsif $facts['ssh']['dsa']['key'] {
    @@sshkey { $title:
      ensure => present,
      key    => $facts['ssh']['dsa']['key'],
      type   => dsa,
    }
  }
  elsif $facts['ssh']['ed25519']['key'] {
    @@sshkey { $title:
      ensure => present,
      key    => $facts['ssh']['ed25519']['key'],
      type   => ed25519,
    }
  }
}
