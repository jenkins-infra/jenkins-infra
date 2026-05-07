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
    [
      'build-essential', # Build requirement
      'ca-certificates',
      'curl',
      'git', # Jenkins agent requirement
      'gpg', # Required to verify downloads
      'gpg-agent', # Required to verify downloads
      'make', # Build requirement
      'openssl',
      'parallel', # Required by Update Center to synchronize with mirrors nodes
      'rsync', # Required by Update Center to send data to remote systems
      'subversion',
      'tar',
      'unzip',
      'zip',
    ].each | $package | {
      ensure_resource('package', $package, { 'ensure' => 'present' })
    }

    # Requires curl, unzip and gpg packages
    include profile::awscli

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

    $maven_version = lookup('profile::jenkinscontroller::jcasc.tools_default_versions.maven', { default_value => undef })

    if $maven_version {

      $maven_major   = regsubst($maven_version, '^([0-9]+)\..*$', '\1')
      $maven_archive = "apache-maven-${maven_version}-bin.tar.gz"

      $base_url = "https://archive.apache.org/dist/maven/maven-${maven_major}/${maven_version}/binaries"

      $maven_url       = "${base_url}/${maven_archive}"
      $maven_checksum  = "${maven_url}.sha512"
      $maven_signature = "${maven_url}.asc"

      $maven_dir = "/usr/share/apache-maven-${maven_major}"
      $maven_bin = "${maven_dir}/bin/mvn"

      $temp_archive  = "/tmp/${maven_archive}"
      $temp_checksum = "${temp_archive}.sha512"
      $temp_sig      = "${temp_archive}.asc"
      $maven_keys_file = '/tmp/maven-keys.gpg'

      exec { 'Download Apache Maven key':
        command => "/usr/bin/curl --silent --show-error --location https://downloads.apache.org/maven/KEYS --output ${maven_keys_file}",
        creates => $maven_keys_file,
        require => Package['curl'],
        unless  => "/usr/bin/gpg --list-keys | /bin/grep 'Apache Maven'",
      }

      exec { 'Import Apache Maven key':
        command => "/usr/bin/gpg --import ${maven_keys_file}",
        require => [
          Package['gpg'],
          Exec['Download Apache Maven key'],
        ],
        unless  => "/usr/bin/gpg --list-keys | /bin/grep 'Apache Maven'",
      }

      exec { "Download Maven ${maven_version}":
        command => "/usr/bin/curl --silent --show-error --location ${maven_url} --output ${temp_archive}",
        require => Package['curl'],
        unless  => "/usr/bin/test -f ${maven_bin} && ${maven_bin} --version | /bin/grep --quiet '${maven_version}'",
      }

      exec { "Download Maven ${maven_version} checksum":
        command => "/usr/bin/curl --silent --show-error --location ${maven_checksum} --output ${temp_checksum}",
        require => Package['curl'],
        unless  => "/usr/bin/test -f ${maven_bin} && ${maven_bin} --version | /bin/grep --quiet '${maven_version}'",
      }

      exec { "Download Maven ${maven_version} signature":
        command => "/usr/bin/curl --silent --show-error --location ${maven_signature} --output ${temp_sig}",
        require => Package['curl'],
        unless  => "/usr/bin/test -f ${maven_bin} && ${maven_bin} --version | /bin/grep --quiet '${maven_version}'",
      }

      exec { "Verify Maven ${maven_version} signature":
        command => "/usr/bin/gpg --verify ${temp_sig}",
        require => [
          Exec['Import Apache Maven key'],
          Exec["Download Maven ${maven_version}"],
          Exec["Download Maven ${maven_version} signature"],
        ],
        unless  => "/usr/bin/test -f ${maven_bin} && ${maven_bin} --version | /bin/grep --quiet '${maven_version}'",
      }

      exec { "Verify Maven ${maven_version} checksum":
        command => "/bin/bash -c \"echo \\$(cat ${temp_checksum})  ${temp_archive} | sha512sum --check\"",
        cwd     => '/tmp',
        require => [
          Exec["Download Maven ${maven_version} checksum"],
          Exec["Download Maven ${maven_version}"],
        ],
        unless  => "/usr/bin/test -f ${maven_bin} && ${maven_bin} --version | /bin/grep --quiet '${maven_version}'",
      }

      file { $maven_dir:
        ensure => directory,
        owner  => 'root',
      }

      exec { "Extract Maven ${maven_version}":
        command => "/usr/bin/tar --extract --gunzip --file=${temp_archive} --directory=${maven_dir} --strip-components=1 && /usr/bin/rm -f ${temp_archive} ${temp_checksum} ${temp_sig}",
        require => [
          Exec["Verify Maven ${maven_version} signature"],
          Exec["Verify Maven ${maven_version} checksum"],
          File[$maven_dir],
          Package['tar'],
        ],
        unless  => "/usr/bin/test -f ${maven_bin} && ${maven_bin} --version | /bin/grep --quiet '${maven_version}'",
      }

      file { '/etc/profile.d/maven.sh':
        ensure  => file,
        mode    => '0755',
        content => "export PATH=${maven_dir}/bin:\$PATH\n",
      }

      file { '/etc/profile.d/java.sh':
        ensure  => file,
        mode    => '0755',
        content => "export JAVA_HOME=/opt/jdk-21\nexport PATH=\$JAVA_HOME/bin:\$PATH\n",
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
