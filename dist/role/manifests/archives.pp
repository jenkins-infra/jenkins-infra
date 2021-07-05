#
# archives requires low resources (2vCPU/8GB RAM)
class role::archives {
  include profile::base
  include profile::archives
}
