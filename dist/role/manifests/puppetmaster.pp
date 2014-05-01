#
# role::puppetmaster defines what a node role that should look like
class role::puppetmaster {
  include profile::accounts
  include profile::puppetmaster
  include profile::r10k
}
