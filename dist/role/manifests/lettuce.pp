#
# Lettuce is a 2vCPU/4GB KVM-based VM at the OSUOSL
class role::lettuce {
  include profile::base
  include profile::sudo::osu
  include profile::apache-cert
  include profile::confluence
}
