#
# Machine to host census data
class role::census {
  include profile::base
  # TODO: uncomment to set up as Jenkins trusted agent for census
  include profile::census
}
