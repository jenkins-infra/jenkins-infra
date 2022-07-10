#
# Machine to receive and host usage information
class role::usage {
  include profile::base
  include profile::usage
}
