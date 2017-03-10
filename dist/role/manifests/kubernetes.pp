# Kubernetes orchestrator
class role::kubernetes{
  include profile::base
  include profile::kubernetes::resources::datadog
}
