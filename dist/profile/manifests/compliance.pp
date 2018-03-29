#
# Enforce various security compliance settings
#
# This profile is intentionally a kind of grab-bag to at least codify
# /somewhere/ some of the security measures and package versions we need to
# have in place.
class profile::compliance {

  # http://www.ubuntu.com/usn/usn-2959-1/
  if $::lsbdistid == 'Ubuntu' and $::lsbdistrelease == '14.04' {
    package { 'libssl1.0.0':
      ensure => '1.0.1f-1ubuntu2.24',
    }
  }
}
