#
# spinach is an Ubuntu VM in the Rackspace Cloud
#
# this machine was donated long time ago and it appears to belong to a then Rackspace employee
# that's no longer with the company. We do not have direct access to this machine, so we need
# to be ready to lose this machine any time
#
class role::spinach {
  include profile::base
  include profile::groovy
  include profile::bind
  include profile::jenkinsadmin
}
