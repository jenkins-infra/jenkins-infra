#
# Role for a Jenkins agent which can/should process census data
class role::census::agent {
  include profile::base
  include role::jenkins::agent

  class { 'profile::census::agent':
    user     => 'jenkins',
    home_dir => '/home/jenkins',
    require  => Class['role::jenkins::agent'],
  }
}
