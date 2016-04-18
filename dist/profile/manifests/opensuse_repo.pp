# This defined type is just to make our template a little bit easier to manage,
# see also:
# https://ask.puppet.com/question/3216/passing-parameters-to-templates/
define profile::opensuse_repo (
  $ensure,
  $docroot,
  $mirror_fqdn) {

  file { "${docroot}/${name}/repodata":
    ensure  => directory,
  }
}
