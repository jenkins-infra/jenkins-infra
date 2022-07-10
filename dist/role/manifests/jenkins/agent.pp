#
# Role for a Jenkins build agent
class role::jenkins::agent {
  include profile::base
  include profile::buildagent
}
