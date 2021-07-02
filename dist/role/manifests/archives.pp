#
# archives is a tiny VM (2vCPU/8GB RAM) on Oracle
class role::archives {
  include profile::base
  include profile::archives
}
