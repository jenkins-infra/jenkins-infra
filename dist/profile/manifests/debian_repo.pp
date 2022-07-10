# This defined type is just to make our template a little bit easier to manage,
# see also:
# https://ask.puppet.com/question/3216/passing-parameters-to-templates/
define profile::debian_repo (
  $ensure,
  $docroot,
  $direct_root,
$mirror_fqdn) {
  file { "${docroot}/${name}/.htaccess":
    ensure  => $ensure,
    content => template("${module_name}/pkgrepo/debian_htaccess.erb"),
  }

  file { "${docroot}/${name}/direct":
    ensure => link,
    target => "${direct_root}/${name}",
  }
}
