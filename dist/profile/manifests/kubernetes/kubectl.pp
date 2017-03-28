#   Class: profile::kubernetes::kubectl
#
#   This class install everything needed to run kubectl command
#   System user, directories, configuration, kubectl binary,...
#
#   Parameters:
#     $user:
#       System use who run kubectl command
#     $home:
#       Kubernetes user home
#     $bin:
#       Binary folder used by k8s user
#       Mainly used for kubectl
#     $resources:
#       Resources folder that contain all kubernetes resources file that will be
#       deploy on Kubernetes cluster
#     $server:
#       Kubernetes server fqdn
#       Used to template .kube/config
#       Cfr .kube/config for more information
#     $clustername:
#       Kubernetes cluster name
#       Used to template .kube/config
#       Cfr .kube/config for more information
#     $certificate_authority_data:
#       Used to template .kube/config
#       Cfr .kube/config for more information
#     $client_certificate_data:
#       Used to template .kube/config
#       Cfr .kube/config for more information
#     $username:
#       Used to template .kube/config
#       Cfr .kube/config for more information
#     $client_key_data:
#       Used to template .kube/config
#       Cfr .kube/config for more information
#
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

  user { $user:
    ensure     => 'present',
    home       => $home,
    managehome => true
  }

  file { $bin:
    ensure => 'directory',
    owner  => $user
  }

  file { $resources:
    ensure => 'directory',
    owner  => $user
  }
  file { "${home}/.kube":
    ensure => 'directory',
    owner  => $user
  }

  file { "${bin}/kubectl":
    ensure => 'present',
    source => 'https://storage.googleapis.com/kubernetes-release/release/v1.5.4/bin/linux/amd64/kubectl',
    owner  => $user,
    mode   => '0755',
  }

  file { "${home}/.kube/config":
    ensure  => 'present',
    content => template("${module_name}/kubernetes/config.erb"),
    owner   => $user,
  }
}
