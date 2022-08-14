#
# A machine capable of processing census information
class profile::census::agent (
  String $user = undef,
  String $home_dir = undef,
) {
  include stdlib # Required to allow using stlib methods and custom datatypes

  $ssh_config = "${home_dir}/.ssh/config"

  ssh_authorized_key { 'usage':
    type => 'ssh-rsa',
    user => $user,
    key  => lookup('usage_ssh_pubkey'),
  }

  ensure_resources('concat', {
      $ssh_config => {
        ensure  => present,
        mode    => '0644',
        owner   => $user,
        group   => $user,
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
  }
}
