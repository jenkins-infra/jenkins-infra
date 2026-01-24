# Profile to ensure `awscli` is installed
class profile::awscli (
  String $version = '',
  Stdlib::Absolutepath $install_dir   = '/var/awscli',
  Stdlib::Absolutepath $bin_dir = '/usr/local/bin',
) {
  # https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions
  if $version != '' {
    # AWS CLI uses the "uname -m" form for architecture, hence the $facts['os']['hardware'] (x86_64 / aarch64)
    $awscli_url = "https://awscli.amazonaws.com/awscli-exe-linux-${$facts['os']['hardware']}-${version}.zip"
    $aws_temp_zip = '/tmp/awscliv2.zip'
    $aws_gpg_key_id = 'FB5DB77FD5C118B80511ADA8A6310ACC4672475C'
    $aws_gpg_key_file = "/tmp/${aws_gpg_key_id}.pub"
    $aws_check_command = "/usr/bin/test -f ${bin_dir}/aws && ${bin_dir}/aws --version | /bin/grep --quiet aws-cli/${version}"

    file { $install_dir:
      ensure  => directory,
    }
    file { $aws_gpg_key_file:
      source  => "puppet:///modules/${module_name}/gpg-keys/${aws_gpg_key_id}.pub",
    }
    ['curl', 'gpg', 'unzip'].each | $package | {
      ensure_resource('package', $package, { 'ensure' => 'present' })
    }
    exec { 'Load AWS CLI Public Key into the GPG agent':
      require => Package['gpg'],
      command => "/usr/bin/gpg --import ${aws_gpg_key_file}",
      unless  => "/usr/bin/gpg --list-public-keys | /bin/grep  ${aws_gpg_key_id}",
    }
    exec { 'Download AWS CLI Installer':
      require => Package['curl'],
      command => "/usr/bin/curl --location --silent --show-error --output ${aws_temp_zip} \"${awscli_url}\"",
      unless  => $aws_check_command,
    }
    exec { 'Download AWS CLI Installer Signature':
      require => Package['curl'],
      command => "/usr/bin/curl --location --silent --show-error --output ${aws_temp_zip}.sig \"${awscli_url}.sig\"",
      unless  => $aws_check_command,
    }
    exec { 'Verify downloaded AWS CLI Installer':
      require => [
        Package['gpg'],
        Exec['Download AWS CLI Installer'],
        Exec['Download AWS CLI Installer Signature'],
      ],
      command => "/usr/bin/gpg --verify ${aws_temp_zip}.sig",
      unless  => $aws_check_command,
    }
    exec { 'Execute AWS CLI Installer':
      require => [
        Exec['Verify downloaded AWS CLI Installer'],
        Package['unzip'],
      ],
      ## Note: deleting the content of the $install_dir prior to the installation avoid the installer to pile-up installation filling the disk
      ## As such, no need for the --update flag for the installer: it will fail if something already exist
      command => "/usr/bin/unzip -o ${aws_temp_zip} -d /tmp && rm -rf ${install_dir} && /bin/bash /tmp/aws/install --install-dir ${install_dir} --bin-dir ${bin_dir}",
      unless  => $aws_check_command,
    }
    exec { 'Cleanup AWS CLI Installer':
      require => [
        Exec['Verify downloaded AWS CLI Installer'],
        Package['unzip'],
      ],
      command => '/bin/rm -rf /tmp/aws*',
      onlyif  => '/bin/ls /tmp/aws*',
    }
  } else {
    file { $install_dir:
      ensure => absent,
      force  => true,
    }
    file { "${bin_dir}/aws":
      ensure => absent,
      force  => true,
    }
  }
}
