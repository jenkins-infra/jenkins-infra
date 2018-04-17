#   Class: profile::kubernetes::kubectl
#
#   This class install everything needed to run kubectl command
#   System user, directories, configuration, kubectl binary,...
#
#   Parameters:
#     $backup:
#       Define backup directory path where to backup kubernetes resources
#
#     $bin:
#       Binary folder used by k8s user
#       Mainly used for kubectl
#
#     $clusters:
#       clusters contains a list of cluster information.
#
#     $config:
#       Directory that contains Kubernetes configuration files
#
#     $home:
#       Kubernetes user home
#
#     $kubeconfig:
#        Kubernetes kubeconfig file path
#
#     $resources:
#       Resources folder that contain all kubernetes resources file that will be
#       deploy on Kubernetes cluster
#
#     $version:
#       Kubectl binary version
#
#     $trash:
#       Kubernetes trash directory that contains deleted resources
#
#     $users:
#       System user who own Kubernetes project
#
class profile::kubernetes::kubectl (
    $backup = $profile::kubernetes::params::backup,
    $bin = $profile::kubernetes::params::bin,
    $clusters = $profile::kubernetes::params::clusters,
    $config = $profile::kubernetes::params::config,
    $home = $profile::kubernetes::params::home,
    $kubeconfig = $profile::kubernetes::params::kubeconfig,
    $resources = $profile::kubernetes::params::resources,
    $version = '1.7.13',
    $trash = $profile::kubernetes::params::trash,
    $user = $profile::kubernetes::params::user
  ) inherits profile::kubernetes::params {

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

  # Cleaning purpose and can be remove once done
  $clusters.each | $cluster | {
    file { "${home}/.kube/${cluster[clustername]}.conf":
      ensure => 'absent',
    }
  }
  ##

  $clusters.each | $cluster | {
    file { "${backup}/${cluster[clustername]}":
      ensure => 'directory',
      owner  => $user
    }

    file { "${resources}/${cluster[clustername]}":
      ensure => 'directory',
      owner  => $user
    }
  }

  file { "${home}/.kube/config":
    ensure  => 'present',
    content => template("${module_name}/kubernetes/config.erb"),
    owner   => $user,
  }
}
