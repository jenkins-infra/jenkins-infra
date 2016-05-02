#
# The r10k profile manages the deploy hooks and r10k environment settings on
# the puppet master.
#
# Deploying r10k is a bit of a chicken-and-egg problem, so this code exists to
# ensure that the configuration that was manually set up is codified.
class profile::r10k {
  file { '/etc/puppetlabs/r10k/r10k.yaml' :
    ensure => file,
    owner  => 'root',
    mode   => '0744',
    source => "puppet:///modules/${module_name}/r10k/r10k.yaml",
  }


  class { '::r10k::webhook::config':
    protected       => true,
    enable_ssl      => false,
    use_mcollective => false,
  }

  class { 'r10k::webhook':
    use_mcollective => false,
    user            => 'root',
    require         => Class['r10k::webhook::config'],
  }

  firewall { '011 allow r10k webhooks':
    proto  => 'tcp',
    port   => 8088,
    action => 'accept',
  }
}
