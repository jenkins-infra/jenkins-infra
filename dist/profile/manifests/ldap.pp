#
# Manage an OpenLDAP authentication service
#
class profile::ldap(
  $database       = 'dc=jenkins-ci,dc=org',
  $admin_dn       = 'cn=admin,dc=jenkins-ci,dc=org',
  $admin_password = undef,
  $ssl_key        = undef,
  $ssl_cert       = undef,
  $ssl_chain      = undef,
) {
  # Not including profile::firewall intentionally here to avoid introducing
  # redundant iptables rules for the same patterns but with different names
  # between jenkins-infra and infra-puppet.
  #
  # If this is to be applied on any role other than cucumber, the caller should
  # expect to include profile::firewall themselves
  include ::firewall
  include ::datadog_agent

  $ssl_dir = '/etc/ldap/ssl'
  $ssl_key_path =   "${ssl_dir}/slap.key"
  $ssl_cert_path =  "${ssl_dir}/slap.crt"
  $ssl_chain_path = "${ssl_dir}/bundle.crt"

  ensure_packages([
      'libaugeas-ruby',          # for augeas based puppet providers
  ])

  class { 'openldap::server':
    ldap_ifs  => ['127.0.0.1'],
    ldapi_ifs => ['/'],
    ldaps_ifs => ['/'],
    ssl_cert  => $ssl_cert_path,
    ssl_key   => $ssl_key_path,
    ssl_ca    => $ssl_chain_path,
    require   => [File[$ssl_key_path],File[$ssl_cert_path],File[$ssl_chain_path]]
  }

  openldap::server::database { $database:
    directory => '/var/lib/ldap',
    rootdn    => $admin_dn,
    rootpw    => $admin_password,
  }


  # Access grants
  ###############
  openldap::server::access {
    "to attrs=userPassword,shadowLastChange by dn=\"${admin_dn}\" on ${database}":
      access => 'write',
  }

  openldap::server::access {
    "to attrs=userPassword,shadowLastChange by anonymous on ${database}":
      access => 'auth',
  }

  openldap::server::access {
    "to attrs=userPassword,shadowLastChange by self on ${database}":
      access => 'write',
  }

  openldap::server::access {
    "to attrs=userPassword,shadowLastChange by * on ${database}":
      access => 'none',
  }
  ###############

  # Indices
  ###############
  $ldap_attr_indices = 'eq,pres,sub'

  openldap::server::dbindex { 'cn index':
    ensure    => present,
    suffix    => $database,
    attribute => 'cn',
    indices   => $ldap_attr_indices,
  }

  openldap::server::dbindex { 'mail index':
    ensure    => present,
    suffix    => $database,
    attribute => 'mail',
    indices   => $ldap_attr_indices,
  }

  openldap::server::dbindex { 'surname index':
    ensure    => present,
    suffix    => $database,
    attribute => 'surname',
    indices   => $ldap_attr_indices,
  }

  openldap::server::dbindex { 'givenname index':
    ensure    => present,
    suffix    => $database,
    attribute => 'givenname',
    indices   => $ldap_attr_indices,
  }

  openldap::server::dbindex { 'ou index':
    ensure    => present,
    suffix    => $database,
    attribute => 'ou',
    indices   => $ldap_attr_indices,
  }

  openldap::server::dbindex { 'uniqueMember index':
    ensure    => present,
    suffix    => $database,
    attribute => 'uniqueMember',
    indices   => 'eq',
  }
  ###############
  ###############

  # SSL Certificates
  file { $ssl_dir:
    ensure  => directory,
    mode    => '0700',
    owner   => $openldap::params::server_owner,
    require => Class['::openldap::server::install'],
  }
  file { $ssl_key_path:
    content => $ssl_key,
    mode    => '0600',
    owner   => $openldap::params::server_owner,
    notify  => Service['slapd'],
    before  => Class['::openldap::server::service'],
  }
  file { $ssl_cert_path:
    content => $ssl_cert,
    mode    => '0644',
    owner   => $openldap::params::server_owner,
    notify  => Service['slapd'],
    before  => Class['::openldap::server::service'],
  }
  file { $ssl_chain_path:
    content => $ssl_chain,
    mode    => '0644',
    owner   => $openldap::params::server_owner,
    notify  => Service['slapd'],
    before  => Class['::openldap::server::service'],
  }

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
    dport   => 636,
    action => 'accept',
  }

  # It appears that puppetlabs-firewall doesn't understand an Array as an
  # option for the source argument. In fact, as far as I know, iptables can
  # only lump multiple IPs into a single rule if they're in a contiguous
  # range, this will have to do
  firewall { '106 accept inbound LDAPS request from hosted Artifactory by JFrog (second IP)':
    proto  => 'tcp',
    source => '50.16.203.43',
    dport   => 636,
    action => 'accept',
  }

  firewall { '106 accept inbound LDAPS request from hosted Artifactory by JFrog (third IP)':
    proto  => 'tcp',
    source => '54.236.124.56',
    dport   => 636,
    action => 'accept',
  }

  # 4th & 5th added by Aug 6 2016 transition
  firewall { '106 accept inbound LDAPS request from hosted Artifactory by JFrog (fourth IP)':
    proto  => 'tcp',
    source => '104.196.52.71',
    dport   => 636,
    action => 'accept',
  }

  firewall { '106 accept inbound LDAPS request from hosted Artifactory by JFrog (fifth IP)':
    proto  => 'tcp',
    source => '104.196.31.82',
    dport   => 636,
    action => 'accept',
  }

  firewall { '106 accept inbound LDAPS request from spambot':
    proto  => 'tcp',
    source => 'home.kohsuke.org',
    dport   => 636,
    action => 'accept',
  }

  firewall { '107 accept inbound LDAPS request from accounts app':
    proto  => 'tcp',
    source => 'accounts.jenkins.io',
    dport   => 636,
    action => 'accept',
  }

  firewall { '107 accept inbound LDAPS request from accounts app on eggplant':
    proto  => 'tcp',
    source => 'eggplant.jenkins.io',
    dport   => 636,
    action => 'accept',
  }

  firewall { '107 accept inbound LDAPS request from puppet.jenkins.io':
    proto  => 'tcp',
    source => 'puppet.jenkins.io',
    dport   => 636,
    action => 'accept',
  }

  firewall { '107 accept inbound LDAPS request from Confluence':
    proto  => 'tcp',
    source => 'wiki.jenkins-ci.org',
    dport   => 636,
    action => 'accept',
  }

  firewall { '107 accept inbound LDAPS request from JIRA':
    proto  => 'tcp',
    source => 'issues.jenkins-ci.org',
    dport   => 636,
    action => 'accept',
  }

  firewall { '107 accept inbound LDAPS from trusted-ci':
    proto  => 'tcp',
    source => '52.91.48.6',
    dport   => 636,
    action => 'accept',
  }

  firewall { '107 accept inbound LDAPS from ci':
    proto  => 'tcp',
    source => 'ci.jenkins.io',
    dport   => 636,
    action => 'accept',
  }

  firewall { '107 accept inbound LDAPS from nginx.azure.jenkins.io':
    proto  => 'tcp',
    source => '13.68.19.38',
    dport   => 636,
    action => 'accept',
  }

  firewall { '107 accept inbound LDAPS from kube cluster prodbean':
    proto  => 'tcp',
    source => '40.79.70.97',
    dport   => 636,
    action => 'accept',
  }

  # normally nobody listens on this port, but when we need to find the
  # source IP address JFrog is using to connect us, run 'stone -d -d
  # localhost:636 9636' and watch the log
  firewall { '106 debugging the LDAPS connection (necessary to report source IP address)':
    proto  => 'tcp',
    dport   => 9636,
    action => 'accept',
  }
}
