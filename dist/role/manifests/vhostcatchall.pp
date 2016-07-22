#
# This role is for a simple apache host which serves as a catch-all for legacy
# domains under jenkins-ci.org
#
# <https://issues.jenkins-ci.org/browse/INFRA-639>
class role::vhostcatchall {
  include profile::base
  include profile::catchall
}
