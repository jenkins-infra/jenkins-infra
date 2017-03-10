# Define default variables
#
class profile::kubernetes::params (
  ){
  $user = 'k8s'
  $home = '/home/k8s'
  $bin = "${home}/.bin"
  $resources = "${home}/resources"

  ### Need to be encrypted
  #config_certificate_authority_data:
}
