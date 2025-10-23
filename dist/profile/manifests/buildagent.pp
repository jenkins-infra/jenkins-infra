# Jenkins build agent connectable via SSH
class profile::buildagent (
  Stdlib::Absolutepath $home_dir         = '/home/jenkins',
  Boolean              $docker           = true,
  Boolean              $trusted_agent    = false,
  Hash                 $private_ssh_keys = {},
  Hash                 $ssh_keys         = {},
  Hash                 $tools_versions   = {},
) {
  include stdlib # Required to allow using stlib methods and custom datatypes
  include limits
  include profile::azcopy

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
        'ca-certificates',
        'curl',
        'git', # Jenkins agent requirement
        'gpg', # Required to verify downloads
        'gpg-agent', # Required to verify downloads
        'groff', # Required by awscli
        'less', # Required by awscli
        'make', # Build requirement
        'openssl',
        'parallel', # Required by Update Center to synchronize with mirrors nodes
        'rsync', # Required by Update Center to send data to remote systems
        'subversion',
        'tar',
        'unzip',
        'zip',
    ])

    if $tools_versions['awscli'] {
      # AWS CLI uses the "uname -m" form for architecture, hence the $facts['os']['hardware'] (x86_64 / aarch64)
      $awscli_url = "https://awscli.amazonaws.com/awscli-exe-linux-${$facts['os']['hardware']}-${tools_versions['awscli']}.zip"
      $aws_temp_zip = '/tmp/awscliv2.zip'
      exec { 'Install aws CLI':
        require => [Package['curl'], Package['unzip'], Package['groff'], Package['less']],
        command => "/usr/bin/curl --silent --show-error --location ${awscli_url} --output ${aws_temp_zip} && unzip -o ${aws_temp_zip} -d /tmp && bash /tmp/aws/install --update && rm -rf /tmp/aws*",
        unless  => "/usr/bin/test -f /usr/local/bin/aws && /usr/local/bin/aws --version | /bin/grep --quiet ${tools_versions['awscli']}",
      }
    }

    $architecture = $facts['os']['architecture'] ? {
      'aarch64' => 'arm64',
      default   => $facts['os']['architecture'],
    }

    $jdk_gpg_key_id = '3B04D753C9050D9A5D343F39843C48A565F8F04B'
    exec { 'Ensure Adoptium GPG key is present':
      require => [
        Package['gpg'],
      ],
      command => "/usr/bin/gpg --keyserver keyserver.ubuntu.com --recv-keys ${jdk_gpg_key_id}",
      unless  => "/usr/bin/gpg --list-keys | grep ${jdk_gpg_key_id}",
    }

    lookup('profile::jenkinscontroller::jcasc.tools_default_versions').filter |$items| { $items[0] =~ /^jdk/ }.each |$jdk_name, $jdk_setup| {
      $major_version = regsubst($jdk_name, 'jdk', '').regsubst($jdk_name, 'jdk-', '')
      $java_dir = "/opt/jdk-${$major_version}"
      $java_bin = "${java_dir}/bin/java"
      $archive_url = $jdk_setup[$facts['kernel'].downcase()][$architecture]
      $filename = basename($archive_url)
      $checksum_url = "${archive_url}.sha256.txt"
      $signature_url = "${archive_url}.sig"
      $temp_archive_file = "/tmp/${filename}"
      $temp_checksum_file = "${temp_archive_file}.sha256.txt"
      $temp_signature_file = "${temp_archive_file}.sig"
      # Note: if we are using JDK8, then the version output does not have the '8u' prefix
      $jdk_version = $jdk_setup['version']
      $jdk_version_to_check = regsubst($jdk_version, '^8u(.*)$', '\1')

      file { $java_dir:
        ensure  => directory,
        owner   => 'root',
        recurse => true,
      }

      exec { "Download JDK ${jdk_version} Installer":
        require => [
          Package['curl'],
        ],
        command => "/usr/bin/curl --silent --show-error --location ${archive_url} --output ${temp_archive_file}",
        unless  => "/usr/bin/test -f ${java_bin} && ${java_bin} -version 2>&1 | /bin/grep --quiet '${jdk_version_to_check}'",
      }
      exec { "Download JDK ${jdk_version} Installer Checksums":
        require => [
          Package['curl'],
        ],
        command => "/usr/bin/curl --silent --show-error --location ${checksum_url} --output ${temp_checksum_file}",
        unless  => "/usr/bin/test -f ${java_bin} && ${java_bin} -version 2>&1 | /bin/grep --quiet '${jdk_version_to_check}'",
      }
      exec { "Download JDK ${jdk_version} Installer Signature":
        require => [
          Package['curl'],
        ],
        command => "/usr/bin/curl --silent --show-error --location ${signature_url} --output ${temp_signature_file}",
        unless  => "/usr/bin/test -f ${java_bin} && ${java_bin} -version 2>&1 | /bin/grep --quiet '${jdk_version_to_check}'",
      }
      exec { "Verify JDK ${jdk_version} Installer Signature":
        require => [
          Package['gpg'],
          Exec["Download JDK ${jdk_version} Installer"],
          Exec["Download JDK ${jdk_version} Installer Checksums"],
          Exec["Download JDK ${jdk_version} Installer Signature"],
        ],
        command => "/usr/bin/gpg --verify ${temp_signature_file}",
        unless  => "/usr/bin/test -f ${java_bin} && ${java_bin} -version 2>&1 | /bin/grep --quiet '${jdk_version_to_check}'",
      }
      exec { "Unarchive Java ${jdk_version}":
        require => [
          Exec["Verify JDK ${jdk_version} Installer Signature"],
          Package['tar'],
          File[$java_dir],
        ],
        command => "/usr/bin/tar --extract --gunzip --file=${temp_archive_file} --directory=${java_dir} --strip-components=1 && /usr/bin/rm -rf ${temp_archive_file} ${temp_checksum_file} ${temp_signature_file}",
        unless  => "/usr/bin/test -f ${java_bin} && ${java_bin} -version 2>&1 | /bin/grep --quiet '${jdk_version_to_check}'",
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
