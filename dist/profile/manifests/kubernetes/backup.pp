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
#     $bin:
#       Define bin directory
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
  String $context = '',
  String $resource = $title,
  String $type = 'secret',
  String $ensure = 'present',
  String $user = $profile::kubernetes::params::user,
  String $bin = $profile::kubernetes::params::bin,
  $clusters = $profile::kubernetes::params::clusters
){
  include ::stdlib
  include profile::kubernetes::params

  if $context == '' {
    fail("Kubernetes context is required for resource ${title}")
  }

  cron { "Backup ${type}/${resource} from ${context}":
    ensure  => $ensure,
    user    => $user,
    name    => "Backup ${type}/${resource} from ${context}",
    command => "${bin}/backup.sh ${context} ${resource} ${type}",
    hour    => '3',
    minute  => '13'
  }
}
