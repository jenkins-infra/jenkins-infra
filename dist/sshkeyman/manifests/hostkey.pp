#
# Export the hostkeys with the specified FQDN
define sshkeyman::hostkey(
  $fqdn = $title,
) {

  @@sshkey { "${fqdn}_rsa":
    ensure => present,
    key    => $::sshrsakey,
    type   => rsa,
  }
  @@sshkey { "${fqdn}_dsa":
    ensure => present,
    key    => $::sshdsakey,
    type   => dsa,
  }
}
