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

  class { 'r10k':
    remote           => 'https://github.com/jenkins-infra/jenkins-infra.git',
    version          => '1.2.1',
    modulepath       => '/etc/puppetlabs/puppet/environments/$environment/dist:/etc/puppetlabs/puppet/environments/$environment/modules:/opt/puppet/share/puppet/modules',
    mange_modulepath => true,
    mcollective      => true,
  }

  ini_setting { 'Update manifest in puppet.conf':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'main',
    setting => 'manifest',
    value   => '/etc/puppetlabs/puppet/environments/$environment/manifests/site.pp',
  }
}
