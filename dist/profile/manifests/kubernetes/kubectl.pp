# Ensure kubectl is installed and correctly configured

class profile::kubernetes::kubectl (
    $user = $profile::kubernetes::params::user,
    $home = $profile::kubernetes::params::home,
    $bin = $profile::kubernetes::params::bin,
    $resources = $profile::kubernetes::params::resources,
    $server = undef,
    $clustername = undef,
    $certificate_authority_data = undef,
    $client_certificate_data = undef,
    $username = undef,
    $client_key_data = undef
  ) {

  include profile::kubernetes::params

  user { 'k8s':
    ensure     => 'present',
    name       => $user,
    home       => $home,
    managehome => true
  }

  file { 'bin':
    ensure => 'directory',
    path   => $bin,
    owner  => $user
  }

  file { 'resources':
    ensure => 'directory',
    path   => $resources,
    owner  => $user
  }
  file { '.kube':
    ensure => 'directory',
    path   => "${home}/.kube",
    owner  => $user
  }

  file { 'kubectl':
    ensure => 'present',
    source => 'https://storage.googleapis.com/kubernetes-release/release/v1.5.4/bin/linux/amd64/kubectl',
    path   => "${bin}/kubectl",
    owner  => $user,
    mode   => '0755',
  }

  file { 'config':
    ensure  => 'present',
    content => template("${module_name}/kubernetes/config.erb"),
    owner   => $user,
    path    => "${home}/.kube/config"
  }
}
