# Run containerized BIND9 to serve both jenkins-ci.org and the jenkins.io zone
class profile::bind (
  # all injected from hiera
  $image_tag,
) {

  include ::firewall
  include profile::docker

  # /etc/bind/local is hard-coded into the Dockerfile here:
  # <https://github.com/jenkins-infra/bind/blob/master/Dockerfile>
  $conf_dir = '/etc/bind/local'

  file { ['/etc/bind', $conf_dir]:
    ensure => directory,
    purge  => true,
  }

  file { "${conf_dir}/jenkins-ci.org.zone":
    ensure  => present,
    notify  => Service['docker-bind'],
    source  => "puppet:///modules/${module_name}/bind/jenkins-ci.org.zone",
    require => File[$conf_dir],
  }

  file { "${conf_dir}/jenkins.io.zone":
    ensure  => present,
    notify  => Service['docker-bind'],
    source  => "puppet:///modules/${module_name}/bind/jenkins.io.zone",
    require => File[$conf_dir],
  }

  file { "${conf_dir}/named.conf.local":
    ensure  => present,
    notify  => Service['docker-bind'],
    source  => "puppet:///modules/${module_name}/bind/named.conf.local",
    require => File[$conf_dir],
  }

  docker::image { 'jenkinsciinfra/bind':
    image_tag => $image_tag,
  }

  docker::run { 'bind':
    command  => undef,
    ports    => ['53:53', '53:53/udp'],
    image    => "jenkinsciinfra/bind:${image_tag}",
    volumes  => ['/etc/bind/local:/etc/bind/local'],
    require  => [File["${conf_dir}/named.conf.local"],
      File["${conf_dir}/jenkins-ci.org.zone"],
    ],
    use_name => true,
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
