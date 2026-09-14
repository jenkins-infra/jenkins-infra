#
# Machine to host census data
class role::census {
  include profile::base
  include role::jenkins::agent
  include profile::census
}
