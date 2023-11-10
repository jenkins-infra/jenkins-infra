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

    # There is no linux_aarch64 azcopy release, considering that aarch64 = arm64 so vagrant can run on Mac Silicon
    $architecture = $facts['os']['architecture'] ? {
      'aarch64' => 'arm64',
      default   => $facts['os']['architecture'],
    }

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

    if $tools_versions['azcopy'] {
      $azcopysemver = split($tools_versions['azcopy'], /-/)[0]
      $azcopy_url = "https://azcopyvnext.azureedge.net/releases/release-${tools_versions['azcopy']}/azcopy_linux_${architecture}_${azcopysemver}.tar.gz"
      exec { 'Install azcopy':
        require => [Package['curl'], Package['tar']],
        command => "/usr/bin/curl --location ${azcopy_url} | /usr/bin/tar --extract --gzip --strip-components=1 --directory=/usr/local/bin/ --wildcards '*/azcopy' && chmod a+x /usr/local/bin/azcopy",
        unless  => "/usr/bin/test -f /usr/local/bin/azcopy && /usr/local/bin/azcopy --version | /bin/grep --quiet ${tools_versions['azcopy']}",
      }
    }

    if $tools_versions['kubectl'] {
      $kubectl_url = "https://dl.k8s.io/release/${tools_versions['kubectl']}/bin/linux/${architecture}/kubectl"
      exec { 'Install kubectl':
        require => [Package['curl']],
        command => "/usr/bin/curl --output kubectl --output-dir /usr/local/bin/ --location ${kubectl_url} && /usr/bin/chmod +x /usr/local/bin/kubectl",
        unless  => "/usr/bin/test -f /usr/local/bin/kubectl && /usr/local/bin/kubectl version | /bin/grep --quiet ${tools_versions['kubectl']}",
      }
    }

    lookup('profile::jenkinscontroller::jcasc.tools_default_versions').filter |$items| { $items[0] =~ /^jdk/ }.each |$jdk_name, $jdk_version| {
      $jdk = {
        name => $jdk_name,
        major_version => regsubst($jdk_name, 'jdk', '').regsubst($jdk_name, 'jdk-', ''),
        version => $jdk_version,
        cpu_arch => $facts['os']['architecture'],
      }
      $java_dir = "/opt/jdk-${$jdk['major_version']}"

      # Use this reusable template to retrieve the URL of the adoptium binary (requires the variable $jdk to be set)
      # Also remove eventual whitespaces (tabs/line returns/etc.)
      $archive_url = strip(template("${module_name}/jdk-adoptium-url.erb"))

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
