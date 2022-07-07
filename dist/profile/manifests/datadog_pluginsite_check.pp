#
# Define datadog check for pluginsite api
# INFRA-1236
#
class profile::datadog_pluginsite_check (
  $sites = [],
) {
  require datadog_agent

  file { 'plugins_api_check.py':
    ensure => file,
    source => "puppet:///modules/${module_name}/datadog_pluginsite_check/plugins_api_check.py",
    path   => '/etc/datadog-agent/checks.d/plugins_api_check.py',
    owner  => $::datadog_agent::params::dd_user,
    group  => $::datadog_agent::params::dd_group,
    notify => Service[$datadog_agent::params::service_name],
  }

  file { 'plugins_api_check.yaml':
    ensure  => file,
    content => template("${module_name}/datadog_pluginsite_check/plugins_api_check.yaml.erb"),
    owner   => $::datadog_agent::params::dd_user,
    group   => $::datadog_agent::params::dd_group,
    path    => "${facts['datadog_agent::params::conf_dir']}/plugins_api_check.yaml",
    notify  => Service[$datadog_agent::params::service_name],
  }
}
