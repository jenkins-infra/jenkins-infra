#   Define: profile::kubernetes::backup
#
#   This definition will backup once per day a resource given by argument from all clusters
#
#   Parameters:
#     $resource:
#       Resource name
#       Default set to $title
#     $type:
#       Resource type (secret,daemonset,...)
#       Default set to 'secret'
#     $ensure:
#       Ensure is set to present or absent (default present)
#     $user:
#       Define user who owns the cronjob
#
#     $clusters:
#       List of cluster information, cfr profile::kubernetes::params for more
#       informations
#
#   Sample usage:
#     profile::kubernetes::backup { 'accountapp-tls':
#       type     => 'secret'
#     }
#
define profile::kubernetes::backup(
  String $resource = $title,
  String $type = 'secret',
  String $ensure = 'present',
  String $user = $profile::kubernetes::params::user,
  $clusters = $profile::kubernetes::params::clusters
){
  include ::stdlib
  include profile::kubernetes::params


  $clusters.each | $cluster | {
    cron { "Backup ${type}/${resource} from ${cluster[clustername]}":
      ensure  => $ensure,
      user    => $user,
      name    => "Backup ${type}/${resource} from ${cluster[clustername]}",
      command => "backup.sh ${cluster[clustername]} ${resource} ${type}",
      hour    => '3',
      minute  => '13'
    }
  }
}
