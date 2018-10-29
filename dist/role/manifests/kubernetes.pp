# Kubernetes orchestrator
class role::kubernetes{
  include profile::base
  include profile::kubernetes::resources::datadog
  include profile::kubernetes::resources::reports
  include profile::kubernetes::resources::chatbot_jenkinsadmin
  include profile::kubernetes::resources::updates_proxy
  include profile::kubernetes::resources::javadoc
  include profile::kubernetes::resources::pluginsite
  include profile::kubernetes::resources::kube_state_metrics
  include profile::kubernetes::resources::fluentd
  include profile::kubernetes::resources::repo_proxy
  include profile::kubernetes::resources::registry
  include profile::kubernetes::resources::accountapp
  include profile::kubernetes::resources::jenkinsio
  include profile::kubernetes::resources::ldap
  include profile::kubernetes::resources::evergreen_gateway
  include profile::kubernetes::resources::evergreen
  include profile::kubernetes::resources::uplink
}
