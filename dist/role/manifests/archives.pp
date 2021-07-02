#
# Okra is a tiny VM (1vCPU/4GB RAM) on Oracle
class role::archives {
  include profile::base
  include profile::archives
}
