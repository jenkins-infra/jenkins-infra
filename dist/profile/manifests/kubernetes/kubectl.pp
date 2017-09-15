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
#     $trash:
#       Kubernetes trash directory that contains deleted resources
#
class profile::kubernetes::kubectl (
    $user = $profile::kubernetes::params::user,
    $home = $profile::kubernetes::params::home,
    $trash = $profile::kubernetes::params::trash,
    $bin = $profile::kubernetes::params::bin,
    $backup = $profile::kubernetes::params::backup,
    $resources = $profile::kubernetes::params::resources,
    $config = $profile::kubernetes::params::config,
    $clusters = $profile::kubernetes::params::clusters,
    $version = '1.6.6'
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

  file { $trash:
    ensure => 'directory',
    owner  => $user
  }

  file { $backup:
    ensure => 'directory',
    owner  => $user
  }

  file { "${home}/.kube":
    ensure => 'directory',
    owner  => $user
  }

  file { "${bin}/kubectl":
    ensure => 'present',
    source => "https://storage.googleapis.com/kubernetes-release/release/v${version}/bin/linux/amd64/kubectl",
    owner  => $user,
    mode   => '0755',
  }

  file { "${bin}/backup.sh":
    ensure  => 'present',
    content => template("${module_name}/kubernetes/backup.sh.erb"),
    owner   => $user,
    mode    => '0755'
  }

  $clusters.each | $cluster | {
    file { "${home}/.kube/${cluster[clustername]}.conf":
      ensure  => 'present',
      content => template("${module_name}/kubernetes/config.erb"),
      owner   => $user,
    }
    file { "${backup}/${cluster[clustername]}":
      ensure => 'directory',
      owner  => $user
    }
  }
}
