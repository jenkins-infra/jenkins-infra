# This defined type is just to make our template a little bit easier to manage,
# see also:
# https://ask.puppet.com/question/3216/passing-parameters-to-templates/
define profile::rpm_repo (
  String $ensure,
  String $owner,
  String $group,
  Stdlib::Absolutepath $docroot,
  Stdlib::Fqdn $repo_fqdn,
) {
  # Redirect binaries to get.jenkins.io (and other redirects)
  file { "${docroot}/${name}/.htaccess":
    ensure  => $ensure,
    content => template("${module_name}/pkgrepo/rpm_htaccess.erb"),
    owner   => $owner,
    group   => $group,
    mode    => '0644',
  }

  file { "${docroot}/${name}/repodata":
    ensure => directory,
    owner  => $owner,
    group  => $group,
    mode   => '0755',
  }
}
