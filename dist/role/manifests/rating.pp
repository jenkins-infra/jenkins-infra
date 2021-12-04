# A server to host rating.jenkins.io
class role::rating {
  include profile::base
  include profile::rating
}
