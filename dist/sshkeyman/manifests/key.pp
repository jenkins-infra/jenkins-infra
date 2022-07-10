#
#
define sshkeyman::key (
  $type,
  $privkey,
  $owner,
  $group    = $owner,
  $key      = undef,
  $ensure   = present,
  $path     = $title,
  $for_host = undef,
) {
  validate_string($owner)
  validate_string($type)
  validate_string($key)
  validate_string($privkey)

  if $key {
    #  Install our public key for completeness' sake
    file { "${title}.pub":
      ensure  => $ensure,
      path    => "${path}.pub",
      owner   => $owner,
      group   => $group,
      content => "${type} ${key}",
    }
  }

  file { $title:
    ensure  => $ensure,
    path    => $path,
    owner   => $owner,
    group   => $group,
    mode    => '0600',
    content => $privkey,
  }

  if $for_host {
    ssh::client::config::user { $owner:
      ensure              => $ensure,
      manage_user_ssh_dir => false,
      options             => {
        "Host ${for_host}" => {
          'IdentityFile'   => $title,
        },
      },
    }
  }
}
