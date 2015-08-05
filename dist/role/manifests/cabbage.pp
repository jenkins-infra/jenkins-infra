#
# Cabbage is a build slave on Rackspace
class role::cabbage {
  include profile::base
  include profile::buildslave
}
