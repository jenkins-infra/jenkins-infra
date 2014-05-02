define jenkins_apache::virtualhost($source=undef, $content=undef) {
  file { "/etc/apache2/sites-available/${name}":
    owner   => root,
    group   => root,
    mode    => '0644',
    source  => $source,
    content => $content,
    require => Package['apache2'],
    notify  => Class['apache::service'],
  }
  file { "/etc/apache2/sites-enabled/${name}":
    ensure  => "../sites-available/${name}",
    notify  => Class['apache::service'],
  }

  # directory to house log files
  file {
    "/var/log/apache2/${name}":
      ensure  => directory,
      owner   => root,
      mode    => '0700';
    "/var/www/${name}" :
      ensure  => directory,
      owner   => 'www-data',
      group   => 'www-data',
      mode    => '0755';
  }
}
