#
# Celery is a Rackspace "Performance 1 - 8GB" class VM with 8x CPUs and 8GB of RAM
# Disk is small and at 40GB system + 80GB data
class role::celery {
  include profile::base
}
