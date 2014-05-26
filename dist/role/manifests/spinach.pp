#
# spinach is an Ubuntu VM in the Rackspace Cloud
class role::spinach {
  include profile::base
  include profile::groovy
  include profile::bind
}
