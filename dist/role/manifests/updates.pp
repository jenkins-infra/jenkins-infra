#
# Role for a machine acting as a mirrorbrain host
class role::updates {
  include profile::base
  include profile::updatesite
}
