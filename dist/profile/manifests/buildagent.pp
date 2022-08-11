# Jenkins build agent connectable via SSH
class profile::buildagent (
  $home_dir         = '/home/jenkins',
  $docker           = true,
  $trusted_agent    = false,
  $ssh_keys         = undef,
) {
  include stdlib
  include limits

  $user = 'jenkins'

  if $docker {
    include profile::docker
    $groups = [$user, 'docker']

    Account <| title == $user |> {
      require  => Package['docker']
    }
  }
  else {
    $groups = [$user]
  }

  account { $user:
    home_dir => $home_dir,
    groups   => $groups,
    ssh_keys => {
      'cucumber' => {
        'key' => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA1l3oZpCJlFspsf6cfa7hovv6NqMB5eAn/+z4SSiaKt9Nsm22dg9xw3Et5MczH0JxHDw4Sdcre7JItecltq0sLbxK6wMEhrp67y0lMujAbcMu7qnp5ZLv9lKSxncOow42jBlzfdYoNSthoKhBtVZ/N30Q8upQQsEXNr+a5fFdj3oLGr8LSj9aRxh0o+nLLL3LPJdY/NeeOYJopj9qNxyP/8VdF2Uh9GaOglWBx1sX3wmJDmJFYvrApE4omxmIHI2nQ0gxKqMVf6M10ImgW7Rr4GJj7i1WIKFpHiRZ6B8C/Ds1PJ2otNLnQGjlp//bCflAmC3Vs7InWcB3CTYLiGnjrw==',
      },
      'celery'   => {
        'key' => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCzBrEqC3IwdKOptY4SUi/RI0+plMVRhs+xrm1ZUizC4qK7UHW3fk/412zb5dkC1FJHFUUJh/Aa7P/OFLxfaf/nVPQ4Nv5ZIMC8g3b7yAWLHrZb7qLpPA8viG1dXXrHMdPLz2uFa2OKtrzlLe4jtyqRtnN8W+dTAWPorkZ9ia1wpD/wdPoKdDtzktBv7gXHpA/jb2arxYWkd560KtQnUbr+LDzrCkeWj2z3BtEGqKxdOtjJMWbLRU9tIkv809VaQJowEs/acwAno/5O7ejYdRzsIicX6GaiHksS6W6vBV4eEn0mA/cX0qFeo1rcGgnXbn4IyglJiwlqm3YSGpKGVJZn',
      },
    },
    comment  => 'Jenkins build node user',
  }

  if $docker {
    file { "${home_dir}/.docker":
      ensure  => directory,
      owner   => $user,
      require => Account[$user],
    }

    if $trusted_agent {
      $docker_config_presence = 'file'
    }
    else {
      $docker_config_presence = 'absent'
    }

    file { "${home_dir}/.docker/config.json":
      ensure  => $docker_config_presence,
      content => lookup('docker_hub_key'),
      owner   => $user,
      require => File["${home_dir}/.docker"],
    }
  }

  if $facts['kernel'] == 'Linux' {
    ensure_packages([
        'build-essential',
        'curl',
        'ca-certificates',
        'make',
        'git',
        'openssl',
        'subversion',
        'tar',
        'unzip',
        'zip',
    ])

    lookup('profile::jenkinscontroller::default_tools').filter |$items| { $items[0] =~ /^jdk/ }.each |$tool, $tool_config| {
      $jdk_major_version = $tool[3,6] # support for major version from 1 up to 3 digits. Goal is to remove the 3 leading characters.
      $java_dir = "/opt/jdk-${$jdk_major_version}"
      case $jdk_major_version {
        '8': {
          $uri_separator = ''
          $stripped_version = inline_template("<%= @tool_config['version'].gsub('-', '') %>")
        }
        '11': {
          $uri_separator = '-'
          $stripped_version = inline_template("<%= @tool_config['version'].gsub('+', '_') %>")
        }
        '17': {
          $uri_separator = '-'
          $stripped_version = inline_template("<%= @tool_config['version'].gsub('+', '_') %>")
        }
      }

      $archive_url = "${tool_config['sourceURL']}/jdk${uri_separator}${$tool_config['version']}/OpenJDK${jdk_major_version}U-jdk_x64_linux_hotspot_${stripped_version}.tar.gz"

      notice("Installing Adoptium JDK ${$jdk_major_version} to ${java_dir} from ${archive_url}")

      file { $java_dir:
        ensure  => directory,
        owner   => 'root',
        mode    => '0755',
        recurse => true,
      }

      Archive { "/tmp/jdk${jdk_major_version}.tgz":
        provider      => 'curl',
        require       => [Package['curl', 'tar'],File[$java_dir]],
        source        => $archive_url,
        extract       => true,
        extract_path  => $java_dir,
        extract_flags => '--extract --strip-components=1 --gunzip -f',
        creates       => "${java_dir}/bin/java",
        cleanup       => true,
      }
    }
  }

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

  if $ssh_keys {
    validate_hash($ssh_keys)
    $private_keys_defaults = {
      'type'  => 'ssh-rsa',
      'owner' => $user,
    }

    create_resources('sshkeyman::key', $ssh_keys, $private_keys_defaults)
  }
}

# vim: nowrap
