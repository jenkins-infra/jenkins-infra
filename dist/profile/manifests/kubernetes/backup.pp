#   Define: profile::kubernetes::backup
#
#   This definition will backup once per day a resource given by argument from all clusters
#
#   Parameters:
#     $bin:
#       Define bin directory
#
#     $context:
#       The name of the kubeconfig context to use
#
#     $ensure:
#       Ensure if resource backup cronjob is set to present or absent (default present)
#
#     $resource:
#       Resource name
#       Default set to $title
#
#     $type:
#       Resource type (secret,daemonset,...)
#       Default set to 'secret'
#
#     $user:
#       Define user who owns the cronjob
#
#   Sample usage:
#     profile::kubernetes::backup { 'accountapp-tls':
#       type     => 'secret'
#     }
#
define profile::kubernetes::backup(
  String $bin = $profile::kubernetes::params::bin,
  String $context = '',
  String $ensure = 'present',
  String $resource = $title,
  String $type = 'secret',
  String $user = $profile::kubernetes::params::user
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
