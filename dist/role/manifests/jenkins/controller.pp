#
# Role for a Jenkins controller
class role::jenkins::controller {
  include profile::base
  include profile::jenkinscontroller
}
