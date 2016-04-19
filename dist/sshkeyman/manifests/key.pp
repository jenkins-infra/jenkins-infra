#
#
define sshkeyman::key(
  $type,
  $privkey,
  $owner,
  $key    = undef,
  $ensure = present,
  $path   = $title,
) {
  validate_string($type)
  validate_string($key)
  validate_string($privkey)

  if $key {
    #  Install our public key for completeness' sake
    file { "${title}.pub":
      ensure  => $ensure,
      path    => "${path}.pub",
      owner   => $owner,
      content => "${type} ${key}"
    }
  }

  file { $title:
    ensure  => $ensure,
    path    => $path,
    owner   => $owner,
    content => $privkey,
  }
}
