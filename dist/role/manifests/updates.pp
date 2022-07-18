#
# Role for a machine acting as an updates.jenkins.io host
class role::updates {
  include profile::base
  include profile::updatesite
}
