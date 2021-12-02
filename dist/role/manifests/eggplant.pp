#
# Eggplant is a VM with 2vCPUs and 2GB RAM at the OSUOSL
class role::eggplant {
  include profile::base
  include profile::sudo::osu
  include profile::catchall
  include profile::javadoc
}
