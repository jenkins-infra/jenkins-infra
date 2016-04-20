#
# Export the hostkeys with the specified FQDN
define sshkeyman::hostkey(
) {

  if $::sshrsakey {
    @@sshkey { $title:
        ensure => present,
        key    => $::sshrsakey,
        type   => rsa,
    }
  }

  if $::sshdsakey {
    @@sshkey { $title:
        ensure => present,
        key    => $::sshdsakey,
        type   => dsa,
    }
  }

  if $::sshecdsakey {
    @@sshkey { $title:
        ensure => present,
        key    => $::sshecdsakey,
        type   => 'ecdsa-sha2-nistp256',
    }
  }

  if $::sshed25519key {
    @@sshkey { $title:
        ensure => present,
        key    => $::sshed25519key,
        type   => ed25519,
    }
  }
}
