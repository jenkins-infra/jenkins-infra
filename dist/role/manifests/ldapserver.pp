# A server to host openldap
class role::ldapserver {
  include profile::base
  include profile::ldap
}
