#
# role::puppetmaster defines what a node role that should look like
class role::puppetmaster {
  include profile::base
  include profile::puppetmaster
  include profile::sudo::osu
  include profile::datadog_http_check
  include profile::datadog_pluginsite_check
}
