# This defined type is just to make our template a little bit easier to manage,
# see also:
# https://ask.puppet.com/question/3216/passing-parameters-to-templates/
define profile::redhat_repo (
  String $ensure,
  Stdlib::Absolutepath $docroot,
  Stdlib::Fqdn $repo_fqdn,
) {
  file { "${docroot}/${name}/jenkins.repo":
    ensure  => $ensure,
    content => template("${module_name}/pkgrepo/jenkins.repo.erb"),
  }

  # Manage some redirects off-host
  # See also: https://issues.jenkins-ci.org/browse/INFRA-967
  file { "${docroot}/${name}/.htaccess":
    ensure  => $ensure,
    content => template("${module_name}/pkgrepo/redhat_htaccess.erb"),
  }

  file { "${docroot}/${name}/repodata":
    ensure  => directory,
  }
}
