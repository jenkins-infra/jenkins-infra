#

# A machine capable of processing census information
class profile::census::agent(
  $user = undef,
  $home_dir = undef,
) {
  include ::stdlib

  validate_string($user)
  validate_string($home_dir)

  ssh_authorized_key { 'usage':
    type    => 'ssh-rsa',
    user    => $user,
    key     => hiera('usage_ssh_pubkey'),
    require => File["${home_dir}/.ssh"],
  }

  ::ssh::client::config::user { $user :
    ensure              => present,
    user_home_dir       => $home_dir,
    manage_user_ssh_dir => false,
    options             => {
      'Host usage.jenkins.io'  => {
        'User'         => 'usagestats',
        'IdentityFile' => "${home_dir}/.ssh/usage",
      },
      'Host census.jenkins.io' => {
        'User'         => 'census',
        'IdentityFile' => "${home_dir}/.ssh/usage",
      },
    },
    require             => File["${home_dir}/.ssh"],
  }

  file { "${home_dir}/.ssh/usage" :
    ensure  => file,
    owner   => $user,
    mode    => '0600',
    content => hiera('usage_ssh_privkey'),
    require => Ssh::Client::Config::User[$user],
  }
}
