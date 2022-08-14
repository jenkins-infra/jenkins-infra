#
# Use the Jenkins CLI to install plugins. This will handle dependencies, since
# it's using the Jenkins CLI
#
define profile::jenkinsplugin (
) {
  exec { "install-plugin-${name}":
    ## Check for plugin presence on the HOST (e.g. with the jenkins home in "/var/lib/jenkins" on the filesystem)
    unless    => "/usr/bin/test -f /var/lib/jenkins/plugins/${name}.jpi || /usr/bin/test -f /var/lib/jenkins/plugins/${name}.hpi",
    ## The container should be running to allow a docker exec command at least
    require   => Docker::Run['jenkins'],
    ## Install the plugin (if needed) in the container, e.g. with the jenkins home mounted in /var/jenkins_home
    command   => "docker exec jenkins jenkins-plugin-cli --plugins ${name} --plugin-download-directory /var/jenkins_home/plugins",
    tries     => 10,
    try_sleep => 10,
    path      => ['/bin', '/usr/bin'],
    notify    => Exec['safe-restart-jenkins'],
  }
}
