## site.pp ##


## Active Configurations ##

# PRIMARY FILEBUCKET
# This configures puppet agent and puppet inspect to back up file contents when
# they run. The Puppet Enterprise console needs this to display file contents
# and differences.

# Define filebucket 'main':
filebucket { 'main':
  server => 'puppet.jenkins.io',
  path   => false,
}

# Make filebucket 'main' the default backup location for all File resources:
File { backup => 'main' }

# DEFAULT NODE
# Node definitions in this file are merged with node data from the console. See
# http://docs.puppetlabs.com/guides/language_guide.html#nodes for more on
# node definitions.

# The default node definition matches any node lacking a more specific node
# definition. If there are no other nodes in this file, classes declared here
# will be included in every node's catalog, *in addition* to any classes
# specified in the console for that node.

node default {
  include profile::base
}


# radish
node 'jenkins-radish.osuosl.org' {
  include role::puppetmaster
}

# edamame (aka jenkins-confluence.osuosl.org)
node 'edamame' {
  include role::edamame
}

# lettuce
node 'lettuce' {
  include role::lettuce
}

# spinach
node 'spinach' {
  include role::spinach
}

# celery
node 'celery' {
  include role::celery
}

# okra
node 'okra' {
  include role::okra
}

# cabbage
node 'cabbage' {
  include role::cabbage
}

# kelp
node 'kelp' {
  include role::kelp
}

# eggplant
node 'eggplant.jenkins-ci.org' {
  include role::eggplant
}

# cucumber (legacy host)
node 'cucumber' {
  include role::cucumber
}
