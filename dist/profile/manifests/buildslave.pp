# Jenkins build slave connectable via SSH
class profile::buildslave(
  $home_dir        = '/home/jenkins',
  $ssh_private_key = undef,
) {
  include ::stdlib
  include profile::docker
  include git
  # Make sure our Ruby class is properly contained so we can require it in a
  # Package resource
  contain('ruby')

  account { 'jenkins':
    home_dir => $home_dir,
    groups   => ['jenkins'],
    ssh_keys => {
                  'cucumber' => {
                    'key' => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA1l3oZpCJlFspsf6cfa7hovv6NqMB5eAn/+z4SSiaKt9Nsm22dg9xw3Et5MczH0JxHDw4Sdcre7JItecltq0sLbxK6wMEhrp67y0lMujAbcMu7qnp5ZLv9lKSxncOow42jBlzfdYoNSthoKhBtVZ/N30Q8upQQsEXNr+a5fFdj3oLGr8LSj9aRxh0o+nLLL3LPJdY/NeeOYJopj9qNxyP/8VdF2Uh9GaOglWBx1sX3wmJDmJFYvrApE4omxmIHI2nQ0gxKqMVf6M10ImgW7Rr4GJj7i1WIKFpHiRZ6B8C/Ds1PJ2otNLnQGjlp//bCflAmC3Vs7InWcB3CTYLiGnjrw==',
                  },
                  'celery'   => {
                    'key' => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCzBrEqC3IwdKOptY4SUi/RI0+plMVRhs+xrm1ZUizC4qK7UHW3fk/412zb5dkC1FJHFUUJh/Aa7P/OFLxfaf/nVPQ4Nv5ZIMC8g3b7yAWLHrZb7qLpPA8viG1dXXrHMdPLz2uFa2OKtrzlLe4jtyqRtnN8W+dTAWPorkZ9ia1wpD/wdPoKdDtzktBv7gXHpA/jb2arxYWkd560KtQnUbr+LDzrCkeWj2z3BtEGqKxdOtjJMWbLRU9tIkv809VaQJowEs/acwAno/5O7ejYdRzsIicX6GaiHksS6W6vBV4eEn0mA/cX0qFeo1rcGgnXbn4IyglJiwlqm3YSGpKGVJZn',
                  },
                },
    comment  => 'Jenkins build slave user',
  }

  file { "${home_dir}/.ssh/id_rsa":
    ensure  => file,
    content => $ssh_private_key,
  }

  package { 'bundler':
    ensure   => installed,
    provider => 'gem',
    require  => Class['ruby'],
  }

  ensure_packages([
      'libxml2-dev',          # for Ruby apps that require nokogiri
      'libxslt1-dev',         # for Ruby apps that require nokogiri
      'libcurl4-openssl-dev', # for curb gem
      'libruby',              # for net/https
      'subversion',
  ])


  # https://help.github.com/articles/what-are-github-s-ssh-key-fingerprints/
  sshkey { 'github-rsa':
    ensure       => present,
    host_aliases => ['github.com'],
    type         => 'ssh-rsa',
    key          => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==',
  }

  sshkey { 'github-dsa':
    ensure => absent,
  }
}

# vim: nowrap
