# profile::puppetagent describe what look like
# a host that run puppet agent
class profile::puppetagent {
  # Add datadog check to monitor puppet agent process
  profile::datadog_check { 'puppetagent-process-check':
    checker => 'process',
    source  => 'puppet:///modules/profile/puppetagent/process_check.yaml',
  }
}
