#
# Class containing basic profile information for setting up the basic firewall
# rules that every role should contain
class profile::firewall {
  include ::firewall

  firewall { '000 accept icmp traffic':
    proto  => 'icmp',
    action => 'accept',
  }

  firewall { '001 accept ssh traffic':
    proto  => 'tcp',
    port   => 22,
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

  firewall {
    '999 drop all UDP requests':
      proto  => 'udp',
      action => 'drop',
  }

  firewall {
    '999 drop all other requests':
      action => 'drop',
  }
}
