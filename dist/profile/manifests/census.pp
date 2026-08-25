#
# Profile to provision the necessary "census" host setup
#
# A "census" host processes the anonymized user data from a "usage" host into infra-statistics
class profile::census (
  Stdlib::Absolutepath $data_disk    = '/srv/census',
) {
  include stdlib # Required to allow using stlib methods and custom datatypes
  include profile::golang # Required for the stats CLI
}
