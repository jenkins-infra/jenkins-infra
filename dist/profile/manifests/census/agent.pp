#

# A machine capable of processing census information
class profile::census::agent(
  $home_dir = undef,
) {
  include ::stdlib

  validate_string($home_dir)
}
