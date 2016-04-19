#
# Export the hostkeys with the specified FQDN
define sshkeyman::hostkey(
) {

  @@sshkey { "${title}_rsa":
    ensure => present,
    key    => $::sshrsakey,
    type   => rsa,
  }
  @@sshkey { "${title}_dsa":
    ensure => present,
    key    => $::sshdsakey,
    type   => dsa,
  }
}
