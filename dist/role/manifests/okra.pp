#
# Okra is a tiny VM (1vCPU/4GB RAM) on Rackspace
class role::okra {
  include profile::base
  include profile::archives
  include profile::bind
  include profile::pluginsite
}
