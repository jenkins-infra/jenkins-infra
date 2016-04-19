# Use the Jenkins CLI to invoke an arbitrary groovy script
#
define profile::jenkinsgroovy (
  $path = $name,
) {
  include ::jenkins::cli

  validate_string($name)
  validate_string($path)

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

  # (ab)using unless to make this exec seem a like it's idempotentn. blech
  exec { "jenkins-groovy-exec ${name}":
    command => 'echo "Something is wrong"',
    unless  => "${cmd} groovy ${path}",
    path    => ['/bin', '/usr/bin'],
  }
}
