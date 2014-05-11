# Jenkins build slave connectable via SSH
class profile::buildslave {
  include git
  # Make sure our Ruby class is properly contained so we can require it in a
  # Package resource
  contain('ruby')

  account { 'jenkins':
    home_dir => '/home/jenkins',
    groups   => ['jenkins'],
    ssh_keys => {
                  'cucumber' => {
                    'key' => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA1l3oZpCJlFspsf6cfa7hovv6NqMB5eAn/+z4SSiaKt9Nsm22dg9xw3Et5MczH0JxHDw4Sdcre7JItecltq0sLbxK6wMEhrp67y0lMujAbcMu7qnp5ZLv9lKSxncOow42jBlzfdYoNSthoKhBtVZ/N30Q8upQQsEXNr+a5fFdj3oLGr8LSj9aRxh0o+nLLL3LPJdY/NeeOYJopj9qNxyP/8VdF2Uh9GaOglWBx1sX3wmJDmJFYvrApE4omxmIHI2nQ0gxKqMVf6M10ImgW7Rr4GJj7i1WIKFpHiRZ6B8C/Ds1PJ2otNLnQGjlp//bCflAmC3Vs7InWcB3CTYLiGnjrw==',
                  }
                },
    comment  => 'Jenkins build slave user',
  }

  package { 'bundler':
    ensure   => installed,
    provider => 'gem',
    require  => Class['ruby'],
  }

  package {
    [
      'libxml2-dev',          # for Ruby apps that require nokogiri
      'libxslt1-dev',         # for Ruby apps that require nokogiri
      'libcurl4-openssl-dev', # for curb gem
      'libruby',              # for net/https
      'subversion',
    ]:
      ensure   => installed,
  }
}

# vim: nowrap
