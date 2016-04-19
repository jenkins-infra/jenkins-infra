#
# Export the hostkeys with the specified FQDN
define sshkeyman::hostkey(
) {

  if $::sshrsakey {
    @@sshkey { "${title}_rsa":
        ensure => present,
        key    => $::sshrsakey,
        type   => rsa,
    }
  }

  if $::sshdsakey {
    @@sshkey { "${title}_dsa":
        ensure => present,
        key    => $::sshdsakey,
        type   => dsa,
    }
  }

  if $::sshecdsakey {
    @@sshkey { "${title}_ecdsa":
        ensure => present,
        key    => $::sshecdsakey,
        type   => 'ecdsa-sha2-nistp256',
    }
  }

  if $::sshed25519key {
    @@sshkey { "${title}_ed25519":
        ensure => present,
        key    => $::sshed25519key,
        type   => ed25519,
    }
  }
}
