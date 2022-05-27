#
# Role for a machine acting as a mirrorbrain host
class role::pkg {
  include profile::base
  include profile::updatesite
  include profile::pkgrepo
}
