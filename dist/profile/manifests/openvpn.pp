# This class deploy an openvpn dockerized service based on the project jenkins-infra/openvpn

class profile::openvpn (
  $image_tag              = 'latest',
  $image                  = 'jenkinsciinfra/openvpn',
  $auth_ldap_password     = undef,
  $auth_ldap_binddn       = 'cn=admin,dc=jenkins-ci,dc=org',
  $auth_ldap_url          = 'ldaps://ldap.jenkins.io',
  $auth_ldap_group_member = 'cn=admins',
  $openvpn_ldap_ca_pem    = undef,
  $openvpn_ca_pem         = undef,
  $openvpn_server_pem     = undef,
  $openvpn_server_key     = undef,
  $openvpn_dh_pem         = undef
) {
  include profile::docker

  validate_string($image_tag)
  validate_string($image)
  validate_string($auth_ldap_password)
  validate_string($auth_ldap_binddn)
  validate_string($auth_ldap_url)
  validate_string($auth_ldap_group_member)
  validate_string($openvpn_ca_pem)
  validate_string($openvpn_server_pem)
  validate_string($openvpn_server_key)
  validate_string($openvpn_dh_pem)

  sysctl { 'net.ipv4.ip_forward':
    ensure => present,
    value  => '1',
  }

  docker::image { $image:
    image_tag => $image_tag
  }

  docker::run { 'openvpn':
    image            => "${image}:${image_tag}",
    env              => [
      "AUTH_LDAP_BINDDN=${auth_ldap_binddn}",
      "AUTH_LDAP_URL=${auth_ldap_url}",
      "AUTH_LDAP_PASSWORD=${auth_ldap_password}",
      "AUTH_LDAP_GROUPS_MEMBER=${auth_ldap_group_member}",
      "OPENVPN_CA_PEM=${openvpn_ca_pem}",
      "OPENVPN_LDAP_CA_PEM=${openvpn_ldap_ca_pem}",
      "OPENVPN_SERVER_PEM=${openvpn_server_pem}",
      "OPENVPN_SERVER_KEY=${openvpn_server_key}",
      "OPENVPN_DH_PEM=${openvpn_dh_pem}"
    ],
    extra_parameters => [ '--restart=always --cap-add=NET_ADMIN' ],
    net              => 'host',
    require          => [Docker::Image[$image]]
  }

  firewall { '107 accept incoming 443 connections':
    proto  => 'tcp',
    port   => 443,
    action => 'accept'
  }

  firewall { '100 snat for network public dmz tier':
    chain       => 'POSTROUTING',
    jump        => 'MASQUERADE',
    proto       => 'all',
    outiface    => 'eth0',
    source      => '10.8.0.0/24',
    destination => '10.0.99.0/24',
    table       => 'nat',
  }

  firewall { '100 snat for network public data tier':
    chain       => 'POSTROUTING',
    jump        => 'MASQUERADE',
    proto       => 'all',
    outiface    => 'eth1',
    source      => '10.8.0.0/24',
    destination => '10.0.2.0/24',
    table       => 'nat',
  }

  firewall { '100 snat for network public app tier':
    chain       => 'POSTROUTING',
    jump        => 'MASQUERADE',
    proto       => 'all',
    outiface    => 'eth2',
    source      => '10.8.0.0/24',
    destination => '10.0.1.0/24',
    table       => 'nat',
  }

}
