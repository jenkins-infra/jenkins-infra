#
# Misc. apache settings
#
#
#
class profile::apache_misc {
  include apache
  # log rotation setting lives in another module
  include apache-logcompressor

  file { '/etc/apache2/conf.d/00-reverseproxy_combined':
    ensure => present,
    source => "puppet:///modules/${module_name}/apache/00-reverseproxy_combined.conf",
    mode   => '0444',
  }

  file { '/etc/apache2/conf.d/other-vhosts-access-log':
    ensure => present,
    source => "puppet:///modules/${module_name}/apache/other-vhosts-access-log.conf",
    mode   => '0444',
  }
}