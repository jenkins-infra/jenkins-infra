#
#
define sshkeyman::key (
  String $type,
  String $privkey,
  String $owner,
  String $key      = '',
  String $for_host = '',
  String $ensure   = 'present',
  String $group    = $owner,
  Stdlib::Absolutepath $path     = $title,
) {
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
