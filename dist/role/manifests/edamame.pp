#
# Edamame is a VM with 2x CPUs and 4GB of RAM at the OSUOSL
class role::edamame {
  include profile::base
  include profile::robobutler
  include profile::sudo::osu
  include profile::bind
  include profile::apachecert
}
