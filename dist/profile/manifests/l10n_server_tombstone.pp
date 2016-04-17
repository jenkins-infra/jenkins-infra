#
# Used to clean up l10n_server
class profile::l10n_server_tombstone {
  $user = 'l10n'
  $dir = "/srv/${user}"

  profile::docker::run_tombstone { 'l10n':
  }

  user { $user:
    ensure => absent,
  }

  # docroot is required for apache::vhost but should never be used because
  # we're proxying everything here
  $docroot = '/var/www/html'

  apache::vhost { 'l10n.jenkins.io':
    ensure  => absent,
    docroot => $docroot,
  }

  file { $dir:
    ensure => absent,
  }
}
