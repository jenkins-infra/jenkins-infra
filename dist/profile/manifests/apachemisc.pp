#
# Misc. apache settings
#
class profile::apachemisc (
  Boolean $ssh_enabled = false,
) {
  include stdlib # Required to allow using stlib methods and custom datatypes
  include apache
  # log rotation setting lives in another module
  include apachelogcompressor

  # enable mod_status for local interface and allow datadog to monitor this
  include apache::mod::status
  file { "${datadog_agent::params::conf_dir}/apache.d/conf.yaml":
    ensure  => file,
    require => Class['datadog_agent'],
    source  => "puppet:///modules/${module_name}/apachemisc/datadog_apache_conf.yaml",
  }

  include apache::mod::proxy
  include apache::mod::proxy_http
  include apache::mod::ssl

  # This should be removed/refactored once this pull request has been merged
  # and released: https://github.com/puppetlabs/puppetlabs-apache/pull/1867
  apache::mod {
    'http2' :
  }

  apache::custom_config { 'http2.conf':
    ensure  => present,
    content => 'Protocols h2 h2c http/1.1',
    require => Apache::Mod['http2'],
  }

  file { '/etc/apache2/conf.d/00-reverseproxy_combined':
    ensure  => file,
    source  => "puppet:///modules/${module_name}/apache/00-reverseproxy_combined.conf",
    mode    => '0444',
    require => Package['apache2-utils'],
    notify  => Service['apache2'],
  }

  file { '/etc/apache2/conf.d/other-vhosts-access-log':
    ensure  => file,
    source  => "puppet:///modules/${module_name}/apache/other-vhosts-access-log.conf",
    mode    => '0444',
    require => Package['apache2-utils'],
    notify  => Service['apache2'],
  }

  # /usr/bin/rotatelogs is (as of 14.04) located in apache2-utils
  package { 'apache2-utils' :
    ensure => present,
  }

  firewall {
    '200 allow http':
      proto  => 'tcp',
      dport  => 80,
      action => 'accept',
  }

  firewall {
    '201 allow https':
      proto  => 'tcp',
      dport  => 443,
      action => 'accept',
  }
}
