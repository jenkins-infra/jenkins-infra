# Run containerized BIND9 to serve both jenkins-ci.org and the jenkins.io zone

#################################################################################
##                                                                             ##
##  THIS CLASS IS DEPRECATED IN FAVOR OF                                       ##
##  https://github.com/jenkins-infra/azure/blob/master/plans/dns_jenkinsio.tf  ##
##  https://github.com/jenkins-infra/azure/blob/master/plans/dns_jenkinsci.tf  ##
##                                                                             ##
#################################################################################


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
    notify  => [ Service['docker-bind'], Exec['sighup-named']],
    source  => "puppet:///modules/${module_name}/bind/jenkins-ci.org.zone",
    require => File[$conf_dir],
  }

  file { "${conf_dir}/jenkins.io.zone":
    ensure  => present,
    notify  => [ Service['docker-bind'], Exec['sighup-named']],
    source  => "puppet:///modules/${module_name}/bind/jenkins.io.zone",
    require => File[$conf_dir],
  }

  file { "${conf_dir}/named.conf.local":
    ensure  => present,
    notify  => Service['docker-bind'],
    source  => "puppet:///modules/${module_name}/bind/named.conf.local",
    require => File[$conf_dir],
  }

  file { 'datadog-dns-check-config':
    ensure => present,
    path   => "${::datadog_agent::params::conf6_dir}/dns_check.yaml",
    source => "puppet:///modules/${module_name}/bind/dns_check.yaml",
    notify => Service['datadog-agent'],
  }

  docker::image { 'jenkinsciinfra/bind':
    image_tag => $image_tag,
  }

  docker::run { 'bind':
    ensure  => 'absent',
    command => undef,
    ports   => ['53:53', '53:53/udp'],
    image   => "jenkinsciinfra/bind:${image_tag}",
    volumes => ['/etc/bind/local:/etc/bind/local'],
    require => [File["${conf_dir}/named.conf.local"],
      File["${conf_dir}/jenkins-ci.org.zone"],
    ],
  }

  exec { 'sighup-named':
    refreshonly => true,
    command     => '/usr/bin/pkill -HUP named',
    onlyif      => '/usr/bin/pgrep named',
  }

  firewall { '900 accept tcp DNS queries':
    proto  => 'tcp',
    dport   => 53,
    action => 'accept',
  }

  firewall { '901 accept udp DNS queries':
    proto  => 'udp',
    dport   => 53,
    action => 'accept',
  }
}
