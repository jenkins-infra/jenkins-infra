#
# Use the Jenkins CLI to install plugins. This will handle dependencies, since
# it's using the Jenkins CLI
#
define profile::jenkinsplugin (
) {
  include ::jenkins::cli

  validate_string($name)

  # NOTE: Some of the code below cribbed from the jenkins::cli class.
  # Unfortunately jenkins::cli::exec executes the CLI `groovy` subcommand. We want
  # to invoke the `install-plugin` subcommand here instead
  $port = jenkins_port()
  $prefix = jenkins_prefix()

  # Provide the -i flag if specified by the user.
  if $::jenkins::cli_ssh_keyfile {
    $auth_arg = "-i ${::jenkins::cli_ssh_keyfile}"
  } else {
    $auth_arg = undef
  }

  # The jenkins cli command with required parameter(s)
  $cmd = join(
    delete_undef_values([
      'java',
      "-jar ${::jenkins::cli::jar}",
      "-s http://localhost:${port}${prefix}",
      $auth_arg,
    ]),
    ' '
  )

  exec { "install-plugin-${name}":
    command => "${cmd} install-plugin ${name}",
    path    => ['/bin', '/usr/bin'],
    unless  => "/usr/bin/test -f /var/lib/jenkins/plugins/${name}.jpi",
    notify  => Exec['safe-restart-jenkins'],
  }
}
