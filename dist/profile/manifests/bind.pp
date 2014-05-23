# Run containerized BIND9 to serve jenkins-ci.org zone
class profile::bind (
  # all injected from hiera
  $image_tag
) {

  include firewall

  file { '/etc/bind/local/jenkins-ci.org.zone':
    ensure  => present,
    notify  => Service['docker-bind'],
    source  => "puppet:///modules/${module_name}/jenkins-ci.org.zone",
  }

  file { '/etc/bind/local/named.conf.local':
    ensure  => present,
    notify  => Service['docker-bind'],
    source  => "puppet:///modules/${module_name}/named.conf.local",
  }

  docker::image { 'jenkinsciinfra/bind':
    image_tag => $image_tag,
  }

  docker::run { 'bind':
    command  => undef,
    ports    => '53:53,53:53/udp',
    image    => "jenkinsciinfra/bind:${image_tag}",
    volumes  => ['/etc/bind/local'],
  }

  firewall { '900 accept tcp DNS queries':
    proto  => 'tcp',
    port   => 53,
    action => 'accept',
  }

  firewall { '901 accept udp DNS queries':
    proto  => 'udp',
    port   => 53,
    action => 'accept',
  }
}
