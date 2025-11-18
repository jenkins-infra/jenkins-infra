# This defined type is just to make our template a little bit easier to manage,
# see also:
# https://ask.puppet.com/question/3216/passing-parameters-to-templates/
define profile::redhat_repo (
  String $ensure,
  Stdlib::Absolutepath $docroot,
  Stdlib::Fqdn $repo_fqdn,
) {
  # Ensure users are redirected to /rpm
  file { "${docroot}/${name}/.htaccess":
    ensure  => $ensure,
    content => template("${module_name}/pkgrepo/redhat_htaccess.erb"),
  }
}
