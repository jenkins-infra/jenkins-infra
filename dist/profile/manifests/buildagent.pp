# Jenkins build agent connectable via SSH
class profile::buildagent (
  Stdlib::Absolutepath $home_dir         = '/home/jenkins',
  Boolean              $docker           = true,
  Boolean              $trusted_agent    = false,
  Hash                 $ssh_keys         = undef,
) {
  include stdlib # Required to allow using stlib methods and custom datatypes
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

    lookup('profile::jenkinscontroller::jcasc.tools_default_versions').filter |$items| { $items[0] =~ /^jdk/ }.each |$jdk_name, $jdk_version| {
      $jdk = {
        name => $jdk_name,
        major_version => regsubst($jdk_name, 'jdk', '').regsubst($jdk_name, 'jdk-', ''),
        version => $jdk_version,
      }
      $java_dir = "/opt/jdk-${$jdk['major_version']}"

      # Use this reusable template to retrieve the URL of the adoptium binary (requires the variable $jdk to be set)
      $archive_url = chop(template("${module_name}/jdk-adoptium-url.erb"))

      notice("Installing Adoptium JDK ${$jdk['major_version']} to ${java_dir} from ${archive_url}")

      file { $java_dir:
        ensure  => directory,
        owner   => 'root',
        recurse => true,
      }

      Archive { "/tmp/jdk${$jdk['major_version']}.tgz":
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
    $private_keys_defaults = {
      'type'  => 'ssh-rsa',
      'owner' => $user,
    }

    create_resources('sshkeyman::key', $ssh_keys, $private_keys_defaults)
  }
}

# vim: nowrap
