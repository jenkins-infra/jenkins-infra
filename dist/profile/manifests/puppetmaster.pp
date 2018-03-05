#
# profile::puppetmaster is a governing what a Jenkins puppetmaster should look
# like
class profile::puppetmaster {
  # pull in all our secret stuff, and install eyaml
  include ::jenkins_keys

  include profile::r10k
  # Set up our IRC reporter
  include ::irc
  include datadog_agent


  # If we're inside of Vagrant we don't have the Service[pe-puppetserver]
  # resource defined since that comes with Puppet Enterprise. We'll define a
  # simple one just to make things 'work'
  if str2bool($::vagrant) {
    service { 'pe-puppetserver':
    }
  }

  # Manage hiera.yaml
  file { '/etc/puppetlabs/puppet/hiera.yaml':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "puppet:///modules/${module_name}/hiera.yaml",
    notify => Service['pe-puppetserver'],
  }

  ini_setting { 'update report handlers':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'master',
    setting => 'reports',
    value   => 'console,puppetdb,irc,datadog_reports',
    notify  => Service['pe-puppetserver'],
    # We really can't use datadog_reports until we have our datadog.yaml in
    # place
    require => File['/etc/dd-agent/datadog.yaml'],
  }

  ini_setting { 'enable master pluginsync':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'master',
    setting => 'pluginsync',
    value   => true,
    notify  => Service['pe-puppetserver'],
  }

  firewall { '010 allow dashboard traffic':
    proto  => 'tcp',
    port   => 443,
    action => 'accept',
  }

  firewall { '012 allow puppet agents':
    proto  => 'tcp',
    port   => 8140,
    action => 'accept',
  }

  firewall { '013 allow mcollective':
    proto  => 'tcp',
    port   => 61613,
    action => 'accept',
  }

  # This puppet enterprise special casing logic cribbed directly from the
  # puppet-irc module which also needs to install gems
  if $::pe_server_version {
    $gem_provider = 'puppetserver_gem'
  }
  else {
    $gem_provider = 'gem'
  }

  # The "datadog_agent::reports" module doesn't really handle puppet enterprise
  # very well at all, in order to make things easier on myself I've decided to
  # just bring in the *two* resources it defines myself
  package { 'dogapi':
    ensure   => present,
    provider => $gem_provider,
  }

  # https://docs.puppet.com/hiera/1/lookup_types.html#deep-merging-in-hiera--120
  package { 'deep_merge':
    ensure   => present,
    provider => $gem_provider,
    notify   => Service['pe-puppetserver'],
  }

  $api_key = $::datadog_agent::api_key
  file { '/etc/dd-agent/datadog.yaml':
    ensure  => file,
    content => template('datadog_agent/datadog-reports.yaml.erb'),
    owner   => 'pe-puppet',
    group   => 'root',
    mode    => '0640',
    require => File['/etc/dd-agent'],
  }
}
