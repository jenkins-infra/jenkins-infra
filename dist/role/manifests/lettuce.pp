#
# Lettuce is a 2vCPU/8GB KVM-based VM at the OSUOSL
class role::lettuce {
  include profile::base
  include profile::sudo::osu
}
