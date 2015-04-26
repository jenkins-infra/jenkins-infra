#
# profile::puppetmaster is a governing what a Jenkins puppetmaster should look
# like
class profile::puppetmaster {
  # pull in all our secret stuff, and install eyaml
  include ::jenkins_keys
  # Set up our IRC reporter
  include ::irc

  # Manage hiera.yaml
  file { '/etc/puppetlabs/puppet/hiera.yaml':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "puppet:///modules/${module_name}/hiera.yaml",
    # The `pe-httpd` service resource is defined in the Puppet master catalog
    # itself (due to classification in PE Console), therefore you won't find
    # any declaration of that resource in this codebase
    notify => Service['pe-puppetserver'],
  }

  ## Ensure we're setting the right SMTP server. The Puppetmaster is located in
  # the OSUOSL datacenter which operates an internal SMTP server for projects'
  # uses
  yaml_setting { 'console smtp server':
    target => '/etc/puppetlabs/console-auth/config.yml',
    key    => 'smtp/address',
    value  => 'smtp.osuosl.org',
    notify => Service['pe-puppetserver'],
  }


  ini_setting { 'Update report handlers':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'master',
    setting => 'reports',
    value   => 'console,puppetdb,irc',
    notify  => Service['pe-puppetserver'],
  }

  firewall { '010 allow dashboard traffic':
    proto  => 'tcp',
    port   => 443,
    action => 'accept',
  }

  firewall { '011 allow r10k webhooks':
    proto  => 'tcp',
    port   => 9013,
    action => 'accept',
  }

  firewall { '012 allow puppet agents':
    proto  => 'tcp',
    port   => 8140,
    action => 'accept',
  }

  service { 'pe-puppetserver':
    ensure     => running,
    hasrestart => true,
    hasstatus  => true,
  }
}
