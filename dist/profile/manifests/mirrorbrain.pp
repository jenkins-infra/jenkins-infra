#
# Configure the mirrorbrain service
class profile::mirrorbrain(
  $pg_host     = 'localhost',
  $pg_database = 'mirrorbrain',
  $pg_username = 'mirrorbrain',
  $pg_password = 'mirrorbrain',

) {
  include profile::firewall
  include ::mirrorbrain
  include ::mirrorbrain::apache
}
