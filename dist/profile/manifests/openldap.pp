#
# Manage an OpenLDAP authentication service
#
class profile::ldap {
  include ::firewall
  include ::datadog_agent

  profile::datadog_check { 'ldap-process-check':
    checker => 'process',
    source  => 'puppet:///modules/profile/ldap/process_check.yaml',
  }

  # Legacy firewall rules from infra-puppet which are copied and
  # pasted here so infra-puppet and jenkins-infra are not clobbering
  # each others' firewall declarations
  firewall { '106 accept inbound LDAPS request from hosted Artifactory by JFrog':
    proto  => 'tcp',
    source => '50.19.229.208',
    port   => 636,
    action => 'accept',
  }

  # It appears that puppetlabs-firewall doesn't understand an Array as an
  # option for the source argument. In fact, as far as I know, iptables can
  # only lump multiple IPs into a single rule if they're in a contiguous
  # range, this will have to do
  firewall { '106 accept inbound LDAPS request from hosted Artifactory by JFrog (second IP)':
    proto  => 'tcp',
    source => '50.16.203.43',
    port   => 636,
    action => 'accept',
  }

  firewall { '106 accept inbound LDAPS request from hosted Artifactory by JFrog (third IP)':
    proto  => 'tcp',
    source => '54.236.124.56',
    port   => 636,
    action => 'accept',
  }

  firewall { '106 accept inbound LDAPS request from spambot':
    proto  => 'tcp',
    source => 'home.kohsuke.org',
    port   => 636,
    action => 'accept',
  }

  firewall { '107 accept inbound LDAPS request from accounts app':
    proto  => 'tcp',
    source => 'accounts.jenkins.io',
    port   => 636,
    action => 'accept',
  }

  # normally nobody listens on this port, but when we need to find the
  # source IP address JFrog is using to connect us, run 'stone -d -d
  # localhost:636 9636' and watch the log
  firewall { '106 debugging the LDAPS connection (necessary to report source IP address)':
    proto  => 'tcp',
    port   => 9636,
    action => 'accept',
  }

  ensure_packages([
      'libaugeas-ruby',          # for augeas based puppet providers
  ])

  class { 'openldap::server': }
  openldap::server::database { 'dc=jenkins-ci,dc=org':
    directory => '/var/lib/ldap',
    rootdn    => 'cn=admin,dc=jenkins-ci,dc=org',
    rootpw    => hiera('ldap_rootpw'),
  }

  openldap::server::access {
  'to attrs=userPassword,shadowLastChange by dn="cn=admin,dc=jenkins-ci,dc=org" on dc=jenkins-ci,dc=org':
    access => 'write';
  'to attrs=userPassword,shadowLastChange by anonymous on dc=jenkins-ci,dc=org':
    access => 'auth';
  'to attrs=userPassword,shadowLastChange by self on dc=jenkins-ci,dc=org':
    access => 'write';
  'to attrs=userPassword,shadowLastChange by * on dc=jenkins-ci,dc=org':
    access => 'none';
  }

}


