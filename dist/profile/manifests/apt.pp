#
# Class for ensuring some basic state around the apt repositories on a machine,
# i.e. that it's updated daily
class profile::apt {

  cron { 'update the apt cache':
    command => 'apt-get update',
    hour    => 2,
    minute  => 20,
  }

}
