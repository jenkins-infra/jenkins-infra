#
# Role for an agent capable of generating the Update Center
class role::updatecenter {
  include role::jenkins::agent
  include profile::updatecenter
}
