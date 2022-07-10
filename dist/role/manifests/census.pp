#
# Machine to host census data
class role::census {
  include profile::base
  include profile::census
}
