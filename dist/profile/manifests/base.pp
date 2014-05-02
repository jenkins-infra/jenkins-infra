#
# Basic profile included in each node
class profile::base {
  include profile::accounts
  include profile::ntp
  include profile::sudo
}
