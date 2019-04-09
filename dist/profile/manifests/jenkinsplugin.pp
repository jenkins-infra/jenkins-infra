#
# Use the Jenkins CLI to install plugins. This will handle dependencies, since
# it's using the Jenkins CLI
#
define profile::jenkinsplugin (
) {
  validate_string($name)

  exec { "install-plugin-${name}":
    command   => "/usr/share/jenkins/idempotent-cli install-plugins.sh ${name}",
    tries     => 10,
    try_sleep => 10,
    path      => ['/bin', '/usr/bin'],
    unless    => "/usr/bin/test -f /var/lib/jenkins/plugins/${name}.jpi",
    require   => Docker::Run['jenkins'],
    notify    => Exec['safe-restart-jenkins-via-ssh-cli'],
  }
}
