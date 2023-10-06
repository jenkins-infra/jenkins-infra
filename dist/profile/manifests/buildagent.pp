# Jenkins build agent connectable via SSH
class profile::buildagent (
  Stdlib::Absolutepath $home_dir         = '/home/jenkins',
  Boolean              $docker           = true,
  Boolean              $trusted_agent    = false,
  Hash                 $private_ssh_keys = {},
  Hash                 $ssh_keys         = {},
  Optional[String]     $aws_credentials  = '',
  Optional[String]     $aws_config       = '',
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
    ssh_keys => $ssh_keys,
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
        'build-essential', # Build requirement
        'awscli', # Required by Update Center to sync buckets
        'ca-certificates',
        'curl',
        'git', # Jenkins agent requirement
        'groff', # Required by awscli
        'less', # Required by awscli
        'make', # Build requirement
        'openssl',
        'rsync', # Required by Update Center to send data to remote systems
        'subversion',
        'tar',
        'unzip',
        'zip',
    ])

    # There is no linux_aarch64 azcopy release, considering that aarch64 = amd64 so vagrant can run on Mac Silicon
    if  $facts['os']['architecture'] == 'aarch64' {
      $architecture = 'arm64'
    } else {
      $architecture =  $facts['os']['architecture']
    }
    $azcopy_url = "https://azcopyvnext.azureedge.net/releases/release-10.21.0-20230928/azcopy_linux_${architecture}_10.21.0.tar.gz"

    exec { 'Install azcopy':
      require => [Package['curl'], Package['tar'], Account[$user]],
      command => "/usr/bin/mkdir -p /tmp/azcopy && /usr/bin/curl ${azcopy_url} | /usr/bin/tar -xz --strip-components=1 -C /tmp/azcopy && /usr/bin/cp /tmp/azcopy/azcopy /usr/local/bin/azcopy && /usr/bin/chmod +x /usr/local/bin/azcopy && /usr/bin/rm -rf /tmp/azcopy/",
      creates => '/usr/local/bin/azcopy',
    }

    file { "${home_dir}/.aws":
      ensure  => directory,
      owner   => $user,
      require => Account[$user],
    }

    if $aws_credentials {
      file { "${home_dir}/.aws/credentials":
        ensure  => file,
        mode    => '0644',
        content => $aws_credentials,
        require => File["${home_dir}/.aws"],
      }
    }

    if $aws_config {
      file { "${home_dir}/.aws/config":
        ensure  => file,
        mode    => '0644',
        content => $aws_config,
        require => File["${home_dir}/.aws"],
      }
    }

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

  if $private_ssh_keys {
    $private_keys_defaults = {
      'type'  => 'ssh-rsa',
      'owner' => $user,
    }

    create_resources('sshkeyman::key', $private_ssh_keys, $private_keys_defaults)
  }
}

# vim: nowrap
