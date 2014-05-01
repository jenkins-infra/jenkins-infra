#
# profile::puppetmaster is a governing what a Jenkins puppetmaster should look
# like
class profile::puppetmaster {
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
    notify => Service['pe-httpd'],
  }

  ## Ensure we're setting the right SMTP server. The Puppetmaster is located in
  # the OSUOSL datacenter which operates an internal SMTP server for projects'
  # uses
  yaml_setting { 'console smtp server':
    target => '/etc/puppetlabs/console-auth/config.yml',
    key    => 'smtp/address',
    value  => 'smtp.osuosl.org',
    notify => Service['pe-httpd'],
  }

  # pull in all our secret stuff, and install eyaml
  include ::jenkins_keys
}
