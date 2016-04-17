#
# Configure the mirrorbrain service
class profile::mirrorbrain {
  include profile::firewall
  include ::mirrorbrain
  include ::mirrorbrain::apache
}
