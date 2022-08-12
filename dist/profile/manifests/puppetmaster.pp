#
# profile::puppetmaster is a governing what a Jenkins puppetmaster should look
# like
class profile::puppetmaster {
  # pull in all our secret stuff, and install eyaml
  include jenkins_keys

  include profile::r10k
  # Set up our IRC reporter
  include irc
  include datadog_agent

  # If we're inside of Vagrant we don't have the Service[pe-puppetserver]
  # resource defined since that comes with Puppet Enterprise. We'll define a
  # simple one just to make things 'work'
  if ($facts['kind'] == 'vagrant') {
    service {
      'pe-puppetserver':
    }
    File <| title == '/etc/puppetlabs/puppet/hiera.yaml' |> {
      notify => Service['pe-puppetserver'],
    }
    Ini_setting <| title == 'enable master pluginsync' |> {
      notify => Service['pe-puppetserver'],
    }
    Package <| title == 'deep_merge' |> {
      notify => Service['pe-puppetserver'],
    }
  }

  # Manage hiera.yaml
  file { '/etc/puppetlabs/puppet/hiera.yaml':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "puppet:///modules/${module_name}/hiera.yaml",
  }

  ini_setting { 'enable master pluginsync':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'master',
    setting => 'pluginsync',
    value   => true,
  }

  firewall { '010 allow dashboard traffic':
    proto  => 'tcp',
    dport  => 443,
    action => 'accept',
    source => '127.0.0.1',
  }

  firewall { '012 allow puppet agents':
    proto  => 'tcp',
    dport  => 8140,
    action => 'accept',
  }

  firewall { '013 allow mcollective':
    proto  => 'tcp',
    dport  => 61613,
    action => 'accept',
  }

  # This puppet enterprise special casing logic cribbed directly from the
  # puppet-irc module which also needs to install gems
  if $facts['pe_server_version'] {
    $gem_provider = 'puppetserver_gem'
  }
  else {
    $gem_provider = 'gem'
  }

  # https://docs.puppet.com/hiera/1/lookup_types.html#deep-merging-in-hiera--120
  package { 'deep_merge':
    ensure   => present,
    provider => $gem_provider,
  }
}
