#
# profile to define the additional sudoer requirements for machines in the
# OSUOSL which have an `osuadmin` role account on them
class profile::sudo::osu {
  include profile::sudo

  sudo::conf { 'osuadmin':
      content => 'osuadmin  ALL=(ALL) ALL',
  }
}
