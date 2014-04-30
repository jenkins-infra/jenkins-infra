#
# profile::puppetmaster is a governing what a Jenkins puppetmaster should look
# like
class profile::puppetmaster {
  # Mange hiera.yaml
  file { '/etc/puppetlabs/puppet/hiera.yaml':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "puppet:///modules/${module_name}/hiera.yaml",
    notify => Service['pe-httpd'],
  }

  ## Ensure we're setting the right SMTP server
  yaml_setting { 'console smtp server':
    target => '/etc/puppetlabs/console-auth/config.yml',
    key    => 'smtp/address',
    value  => 'smtp.osuosl.org',
    notify => Service['pe-httpd'],
  }

  # pull in all our secret stuff, and install eyaml
  include ::jenkins_keys
}
