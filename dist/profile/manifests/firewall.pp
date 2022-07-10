#
# Class containing basic profile information for setting up the basic firewall
# rules that every role should contain
class profile::firewall {
  include firewall

  firewall { '000 accept icmp traffic':
    proto  => 'icmp',
    action => 'accept',
  }

  firewall { '001 accept ssh traffic':
    proto  => 'tcp',
    dport  => 22,
    action => 'accept',
  }

  firewall { '002 accept local traffic':
    # traffic within localhost is OK
    iniface => 'lo',
    action  => 'accept',
  }

  firewall { '003 accept established connections':
    # this is needed to make outbound connections work, such as database connection
    state  => ['RELATED','ESTABLISHED'],
    action => 'accept',
  }

  # Unfortunately I don't have the time to block all UDP traffic while still
  # preserving DNS UDP traffic
  firewall {
    '900 drop all UDP port 111 requests':
      proto  => 'udp',
      dport  => 111,
      action => 'drop',
  }

  firewall {
    '999 drop all UDP requests':
      ensure => absent,
  }

  firewall {
    '999 drop all other requests':
      action => 'drop',
  }
}
