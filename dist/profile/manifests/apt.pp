#
# Class for ensuring some basic state around the apt repositories on a machine,
# i.e. that it's updated daily
class profile::apt {
  class { 'apt':
    update => {
      frequency => 'daily',
    },
  }
}
