#
# The r10k profile manages the deploy hooks and r10k environment settings on
# the puppet master.
#
# Deploying r10k is a bit of a chicken-and-egg problem, so this code exists to
# ensure that the configuration that was manually set up is codified.
class profile::r10k {
  # Here we get our config for r10k from hiera.
  # currently this hash is only used by the templates below
  $r10k_options = hiera('r10k_options')

  class { '::r10k':
    remote            => 'https://github.com/jenkins-infra/jenkins-infra.git',
    version           => '1.2.1',
    modulepath        => '/etc/puppetlabs/puppet/environments/$environment/dist:/etc/puppetlabs/puppet/environments/$environment/modules:/opt/puppet/share/puppet/modules',
    manage_modulepath => true,
    mcollective       => true,
  }

  ini_setting { 'Update manifest in puppet.conf':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'main',
    setting => 'manifest',
    value   => '/etc/puppetlabs/puppet/environments/$environment/manifests/site.pp',
  }

  case $::osfamily {
    'redhat': {
      file { '/etc/init.d/r10k_deployhook.init':
        ensure  => file,
        owner   => root,
        group   => root,
        mode    => '0755',
        content => template("${module_name}/r10k_deployhook.init.erb"),
        notify  => Service['r10k_deployhook'],
      }
    }

    'debian': {
      file { '/etc/init/r10k_deployhook.conf':
        ensure  => file,
        owner   => root,
        group   => root,
        mode    => '0644',
        content => template("${module_name}/r10k_deployhook.upstart.erb"),
        alias   => 'deployhook_init',
      }
    }

    default: { fail("${module_name} is not supported on ${::osfamily}") }
  }

  file { "${r10k_options['deployhooks_logdir']}/deployhooks":
    ensure => file,
    owner  => peadmin,
    group  => peadmin,
    mode   => '0660',
  }

  file { "${r10k_options['deployhooks_logdir']}/mco":
    ensure => file,
    owner  => peadmin,
    group  => peadmin,
    mode   => '0660',
  }

  package { 'sinatra':
    ensure   => present,
    provider => pe_gem,
  }

  package { 'webrick':
    ensure   => present,
    provider => pe_gem,
  }

  file { '/usr/local/bin/r10k_deployhook':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    content => template("${module_name}/r10k_deployhook.erb"),
    require => [ Package['sinatra'], Package['webrick'] ],
    notify  => Service['r10k_deployhook'],
  }

  service { 'r10k_deployhook':
    ensure    => running,
    enable    => true,
  }
}
