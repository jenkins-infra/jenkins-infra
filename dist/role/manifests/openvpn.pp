#
# A server that run an openvpn service
class role::openvpn {
  include profile::base
  include profile::openvpn
}
