#
# role::puppetmaster defines what a node role that should look like
class role::puppetmaster {
  include profile::account
  include profile::puppetmaster
  include profile::r10k
}
