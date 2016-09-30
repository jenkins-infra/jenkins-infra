# Use the Jenkins CLI to invoke an arbitrary groovy script
#
define profile::jenkinsgroovy (
  $path = $name,
) {
  include ::jenkins::cli

  validate_string($name)
  validate_string($path)

  # (ab)using unless to make this exec seem a like it's idempotent. blech
  exec { "jenkins-groovy-exec ${name}":
    command   => 'echo "Something is wrong"',
    tries     => $::jenkins::cli_tries,
    try_sleep => $::jenkins::cli_try_sleep,
    unless    => "/usr/share/jenkins/idempotent-cli groovy ${path}",
    require   => Docker::Run['jenkins'],
    path      => ['/bin', '/usr/bin'],
  }
}
