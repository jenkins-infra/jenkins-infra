# Jenkins build slave connectable via SSH
class profile::buildslave {
  File {
    owner       => 'jenkins',
    group       => 'jenkins',
  }

  group { 'jenkins' :
    ensure  => present,
  }

  user { 'jenkins' :
    ensure  => present,
    gid     => 'jenkins',
    shell   => '/bin/bash',
    home    => '/home/jenkins',
  }

  file { '/home/jenkins' :
    ensure      => directory,
    require     => User['jenkins'],
  }

  file { '/home/jenkins/.ssh' :
    ensure      => directory,
    require     => File['/home/jenkins'],
  }

  ssh_authorized_key { 'jenkins' :
    ensure  => present,
    user    => 'jenkins',
    require => File['/home/jenkins/.ssh'],
    key     => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA1l3oZpCJlFspsf6cfa7hovv6NqMB5eAn/+z4SSiaKt9Nsm22dg9xw3Et5MczH0JxHDw4Sdcre7JItecltq0sLbxK6wMEhrp67y0lMujAbcMu7qnp5ZLv9lKSxncOow42jBlzfdYoNSthoKhBtVZ/N30Q8upQQsEXNr+a5fFdj3oLGr8LSj9aRxh0o+nLLL3LPJdY/NeeOYJopj9qNxyP/8VdF2Uh9GaOglWBx1sX3wmJDmJFYvrApE4omxmIHI2nQ0gxKqMVf6M10ImgW7Rr4GJj7i1WIKFpHiRZ6B8C/Ds1PJ2otNLnQGjlp//bCflAmC3Vs7InWcB3CTYLiGnjrw==',
    type    => 'rsa',
    name    => 'hudson@cucumber';
  }

  package {
    'bundler':
      ensure   => installed,
      provider => 'gem';
    [
      'libxml2-dev',          # for Ruby apps that require nokogiri
      'libxslt1-dev',         # for Ruby apps that require nokogiri
      'libcurl4-openssl-dev', # for curb gem
      'libopenssl-ruby',      # for net/https
      'subversion',
      'git'
    ]:
      ensure   => installed;
  }

  file {
    # put RubyGems bin directory into PATH
    '/etc/profile.d/gem.sh' :
    source => "puppet:///modules/${module_name}/buildslave/gem.sh";
  }
}