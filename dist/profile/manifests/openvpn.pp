# This class deploy an openvpn dockerized service based on the project jenkins-infra/openvpn

class profile::openvpn (
  String $image_tag                    = 'latest',
  String $image                        = 'jenkinsciinfra/openvpn',
  Optional[String] $auth_ldap_password = undef,
  String $auth_ldap_binddn             = 'cn=admin,dc=jenkins-ci,dc=org',
  String $auth_ldap_url                = 'ldaps://ldap.jenkins.io',
  String $auth_ldap_group_member       = 'cn=all',
  Optional[String] $openvpn_ca_pem     = undef,
  Optional[String] $openvpn_server_pem = undef,
  Optional[String] $openvpn_server_key = undef,
  Optional[String] $openvpn_dh_pem     = undef,
  Hash $vpn_network                    = {},
  Hash $networks                       = {}
) {
  include stdlib # Required to allow using stlib methods and custom datatypes
  include profile::docker

  sysctl { 'net.ipv4.ip_forward':
    ensure => present,
    value  => '1',
  }

  docker::image { $image:
    image_tag => $image_tag,
  }

  docker::run { 'openvpn':
    image            => "${image}:${image_tag}",
    env              => [
      "AUTH_LDAP_BINDDN=${auth_ldap_binddn}",
      "AUTH_LDAP_URL=${auth_ldap_url}",
      "AUTH_LDAP_PASSWORD=${auth_ldap_password}",
      "AUTH_LDAP_GROUPS_MEMBER=${auth_ldap_group_member}",
      "OPENVPN_CA_PEM=${openvpn_ca_pem}",
      "OPENVPN_SERVER_PEM=${openvpn_server_pem}",
      "OPENVPN_SERVER_KEY=${openvpn_server_key}",
      "OPENVPN_DH_PEM=${openvpn_dh_pem}",
      "OPENVPN_NETWORK_NAME=${vpn_network['name']}",
      "OPENVPN_SERVER_SUBNET=${split($vpn_network['cidr'], '/')[0]}",
      # TODO: replace by a conversion from profile network cidr
      "OPENVPN_SERVER_NETMASK=${vpn_network['netmask']}",
    ],
    extra_parameters => ['--restart=always --cap-add=NET_ADMIN'],
    net              => 'host',
    require          => [Docker::Image[$image]],
  }

  file { '/etc/cloud':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    recurse => true,
  }

  file { '/etc/cloud/cloud.cfg.d':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    recurse => true,
    require => [
      File['/etc/cloud'],
    ],
  }

  # Ensure cloud-init doesn't manage network to ensure the order of eth1 and eth2 if this last one is defined (ie 3 interfaces) (netplan config + netplan apply + systemd, in Ubuntu Bionic)
  if $networks.length > 2 {
    file { '/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg':
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      require => [
        File['/etc/cloud/cloud.cfg.d'],
      ],
      content => 'network: {config: disabled}',
    }
  }

  file { '/etc/netplan/':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    recurse => true,
  }

  # Define eth interfaces with the correct mac addresses
  # We assume the parent folder already exists
  file { '/etc/netplan/90-network-config.yaml':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    require => [
      File['/etc/netplan/'],
    ],
    content => template("${module_name}/openvpn/90-network-config.yaml.erb"),
  }

  # The CLI '/sbin/route' included in net-tools is required to create custom routes for peered networks
  package { 'net-tools':
    ensure => present,
  }

  # Allow openvpn clients (incoming 443)
  firewall { '107 accept incoming 443 connections':
    proto   => 'tcp',
    dport   => 443,
    action  => 'accept',
    iniface => 'eth0',
  }

  # Allow SSH clients (incoming 2)
  firewall { '107 accept incoming 22 connections':
    proto   => 'tcp',
    dport   => 22,
    action  => 'accept',
    iniface => 'eth0',
  }

  # Create firewall rules and route for each specified NIC to allow routing from VPN virtual networks to different networks
  lookup('profile::openvpn::networks').each |$network_nic, $network_setup| {
    # Only get the 3 first digits of the CIDR (`10.0.0.0/24` returns `10.0.0`)
    $network_prefix = join(split($network_setup['network_cidr'], '[.]')[0,3], '.')

    # A given NIC has a "main" CIDR (its network) but may also be used for routes to peered networks
    # If there are any peered network, then add a manual route
    if $network_setup['peered_network_cidrs'] and $network_setup['peered_network_cidrs'].length > 0 {
      $network_setup['peered_network_cidrs'].each | $peered_net_cidr | {
        # Remove the mask from CIDR to only keep the network Ipv4 (`10.0.0.0/24` returns `10.0.0.0`)
        $peered_network_ip  = split($peered_net_cidr, '/')[0]
        # Only get the 3 first digits of the IPv4 (`10.0.0.0` returns `10.0.0`)
        $peered_network_prefix = join(split($peered_network_ip, '[.]')[0,3], '.')

        ## Custom routes for peered networks
        $gateway = "${network_prefix}.1"
        exec { "addroute ${peered_network_prefix}.0 through ${gateway} (NIC ${network_nic})":
          command => "ip route add ${peered_net_cidr} via ${gateway} dev ${network_nic}",
          unless  => "route | grep ${peered_network_prefix}.0",
          require => [
            # The CLI command 'route' is needed
            Package['net-tools'],
          ],
          path    => '/usr/bin:/usr/sbin:/bin:/sbin',
        }
      }
    }

    # The lambda filter is used to cleanup the array from empty element (when $network_setup['peered_network_cidrs'] is undefined)
    $destinations_cidrs = ([$network_setup['network_cidr']] + $network_setup['peered_network_cidrs']).filter |$item| {
      $item and $item.length > 0
    }

    # Add all the destinations per interface
    $destinations_cidrs.each |$destination_cidr| {
      # Then add firewall rules to allow routing through networks using masquerading
      firewall { "100 allow routing from ${vpn_network['cidr']} to ${destination_cidr} on ports 80/443":
        chain       => 'POSTROUTING',
        jump        => 'MASQUERADE',
        proto       => 'tcp',
        outiface    => $network_nic,
        source      => $vpn_network['cidr'],
        dport       => [80,443],
        destination => $destination_cidr,
        table       => 'nat',
      }
    }
  }
}
