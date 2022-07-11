#

# A machine capable of processing census information
class profile::census::agent (
  $user = undef,
  $home_dir = undef,
) {
  include stdlib

  validate_string($user)
  validate_string($home_dir)

  $ssh_config = "${home_dir}/.ssh/config"

  ssh_authorized_key { 'usage':
    type    => 'ssh-rsa',
    user    => $user,
    key     => lookup('usage_ssh_pubkey'),
    require => File["${home_dir}/.ssh"],
  }

  ensure_resources('concat', {
      $ssh_config => {
        ensure  => present,
        mode    => '0644',
        owner   => $user,
        group   => $user,
        require => File["${home_dir}/.ssh"],
      },
    }
  )

  concat::fragment { 'census-key concat':
    target  => $ssh_config,
    order   => '10',
    content => "
Host census.jenkins.io
  User census
  IdentityFile ${home_dir}/.ssh/usage
",
  }

  concat::fragment { 'usage-key concat':
    target  => $ssh_config,
    order   => '11',
    content => "
Host usage.jenkins.io
  User usagestats
  IdentityFile ${home_dir}/.ssh/usage
",
  }

  file { "${home_dir}/.ssh/usage" :
    ensure  => file,
    owner   => $user,
    mode    => '0600',
    content => lookup('usage_ssh_privkey'),
    require => File["${home_dir}/.ssh"],
  }
}
