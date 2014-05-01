#
# Main sudo management profile
class profile::sudo {
  include ::sudo

  sudo::conf { 'env-defaults':
    content => 'Defaults        env_reset',
  }

  sudo::conf { 'secure-path':
    content => 'Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"',
  }

  sudo::conf { 'root':
    content  => 'root ALL=(ALL) ALL',
  }

  sudo::conf { 'admins':
    priority => '10',
    content  => '%admin ALL=(ALL) ALL',
  }

  sudo::conf { 'sudo':
    priority => '10',
    content  => '%sudo ALL=(ALL) ALL',
  }
}
