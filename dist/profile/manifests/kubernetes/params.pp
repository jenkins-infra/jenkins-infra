#   Class: profile::kubernetes::params default variables
#
#   This class define default parameters
#
class profile::kubernetes::params (
  ){
  $user = 'k8s'
  $home = "/home/${user}"
  $bin = "${home}/.bin"
  $resources = "${home}/resources"
  $trash = "${home}/trash"
}
