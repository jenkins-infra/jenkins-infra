#
# Cucumber is an old machine based in a Contegix datacenter
class role::cucumber {
  include profile::diagnostics
  include profile::ldap
}
