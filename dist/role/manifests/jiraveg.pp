#
# server that hosts issues.jenkins-ci.org
class role::jiraveg {
  include profile::base
  include profile::jiraveg
}
