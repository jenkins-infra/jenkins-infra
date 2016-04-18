#
# Role for a Jenkins master
class role::jenkins::master {
  include profile::base
  include profile::buildmaster
}
