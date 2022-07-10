#
# A define that cleans up the left over from docker::run
#
define profile::docker::run_tombstone {
  $initscript = "/etc/init/docker-${title}.conf"

  file { $initscript:
    ensure  => absent,
  }

  service { "docker-${title}":
    ensure     => stopped,
  }
}
