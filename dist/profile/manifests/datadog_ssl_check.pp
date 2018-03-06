#   ! This puppet class is deprecated as it is now included by datadog module
#
#
# Define datadog check for ssl expiration
# Inspired by: https://workshop.avatarnewyork.com/project/datadog-ssl-expires-check/
#
#
#
class profile::datadog_ssl_check (
  $sites = [],
  $ensure = 'absent'
){
  require datadog_agent

  file { 'ssl_check_expire_days.py':
    ensure => $ensure,
    source => "puppet:///modules/${module_name}/datadog_ssl_check/ssl_check_expire_days.py",
    path   => '/etc/dd-agent/checks.d/ssl_check_expire_days.py',
    owner  => $::datadog_agent::params::dd_user,
    group  => $::datadog_agent::params::dd_group,
    notify => Service['datadog-agent']
  }

  file { 'ssl_check_expire_days.yaml':
    ensure  => $ensure,
    content => template("${module_name}/datadog_ssl_check/ssl_check_expire_days.yaml.erb"),
    owner   => $::datadog_agent::params::dd_user,
    group   => $::datadog_agent::params::dd_group,
    path    => "${::datadog_agent::params::conf6_dir}/ssl_check_expire_days.yaml",
    notify  => Service['datadog-agent']
  }
}
