# A server to host openldap
class role::kale(){
  include profile::base
  include profile::openldap
}
