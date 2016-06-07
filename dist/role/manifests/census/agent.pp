#
# Role for a Jenkins agent which can/should process census data
class role::census::agent {
  include profile::base
  include role::jenkins::agent

  include profile::census::agent
}
