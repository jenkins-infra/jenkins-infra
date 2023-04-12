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
    type         => 'ssh-ed25519',
    key          => 'AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl',
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
