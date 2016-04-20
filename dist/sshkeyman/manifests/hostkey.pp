#
# Export the hostkeys with the specified FQDN
define sshkeyman::hostkey(
) {

  if $::sshecdsakey {
    @@sshkey { $title:
      ensure => present,
      key    => $::sshecdsakey,
      type   => 'ecdsa-sha2-nistp256',
    }
  }
  elsif $::sshrsakey {
    @@sshkey { $title:
      ensure => present,
      key    => $::sshrsakey,
      type   => rsa,
    }
  }
  elsif $::sshdsakey {
    @@sshkey { $title:
      ensure => present,
      key    => $::sshdsakey,
      type   => dsa,
    }
  }
  elsif $::sshed25519key {
    @@sshkey { $title:
      ensure => present,
      key    => $::sshed25519key,
      type   => ed25519,
    }
  }
}
