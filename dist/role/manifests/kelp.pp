#
# Kelp is a build slave on Rackspace with 8vCPUs and 30GB RAM
#
# This node also has a massive (300GB) data disk mounted as /home/jenkins
class role::kelp {
  include profile::base
  include profile::bind
  include profile::buildslave
  include profile::jenkinsadmin
  include profile::pluginsite
}
