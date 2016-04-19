#
# Use the Jenkins CLI to install plugins. This will handle dependencies, since
# it's using the Jenkins CLI
#
define profile::jenkinsplugin (
) {
  include ::jenkins::cli

  validate_string($name)

  exec { "install-plugin-${name}":
    command   => "$/usr/share/jenkins/idempotent-cli install-plugin ${name}",
    tries     => $::jenkins::cli_tries,
    try_sleep => $::jenkins::cli_try_sleep,
    path      => ['/bin', '/usr/bin'],
    unless    => "/usr/bin/test -f /var/lib/jenkins/plugins/${name}.jpi",
    notify    => Exec['safe-restart-jenkins'],
  }
}
