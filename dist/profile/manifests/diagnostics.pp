#
# The diagnostics profile will add some diagnostics tools for our internal use
# where ever this profile is applied
#
class profile::diagnostics {
  include stdlib
  include datadog_agent

  ensure_packages(['htop', 'strace'])
}
