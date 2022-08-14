# This defined type is just to make our template a little bit easier to manage,
# see also:
# https://ask.puppet.com/question/3216/passing-parameters-to-templates/
define profile::debian_repo (
  String               $ensure,
  Stdlib::Absolutepath $docroot,
  Stdlib::Absolutepath $direct_root,
  Stdlib::Fqdn         $mirror_fqdn,
) {
  include stdlib # Required to allow using stlib methods and custom datatypes

  file { "${docroot}/${name}/.htaccess":
    ensure  => $ensure,
    content => template("${module_name}/pkgrepo/debian_htaccess.erb"),
  }

  file { "${docroot}/${name}/direct":
    ensure => link,
    target => "${direct_root}/${name}",
  }
}
