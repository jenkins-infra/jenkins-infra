# Class: profile::datadog_http_check
#
# This class will install the necessary config to monitor jenkins infrastructure https endpoint
# Parameters:
#     contact
#       Specify a list of users to notify regarding http_check alert
#
#     days_critical
#     days_warning
#        The check_certificate_expiration will instruct the check
#        to create a service check that checks the expiration of the
#        ssl certificate. Allow for a warning to occur when x days are
#        left in the certificate, and alternatively raise a critical
#        warning if the certificate is y days from the expiration date.
#        The SSL certificate will always be validated for this additional
#         service check regardless of the value of disable_ssl_validation
#
#     timeout
#        The (optional) timeout in seconds.
#
#     threshold
#     window
#        The (optional) window and threshold parameters allow you to trigger
#        alerts only if the check fails x times within the last y attempts
#        where x is the threshold and y is the window.
#

class profile::datadog_http_check(
  $contact = ['pagerduty'],
  $days_warning = 30,
  $days_critical = 10,
  $timeout = 3,
  $treshold = 3,
  $window = 5
){

  include datadog_agent

  class { 'datadog_agent::integrations::http_check':
    instances => [{
      'sitename'                     => 'plugins.jenkins.io',
      'url'                          => 'https://plugins.jenkins.io',
      'timeout'                      => $timeout,
      'treshold'                     => $treshold,
      'window'                       => $window,
      'collect_response_time'        => true ,
      'check_certificate_expiration' => true,
      'days_warning'                 => $days_warning,
      'days_critical'                => $days_critical,
      'contact'                      => $contact,
      'tags'                         => ['production','jenkins.io']
    },
    {
      'sitename'                     => 'jenkins.io',
      'url'                          => 'https://jenkins.io',
      'timeout'                      => $timeout,
      'treshold'                     => $treshold,
      'window'                       => $window,
      'collect_response_time'        => true ,
      'check_certificate_expiration' => true,
      'days_warning'                 => $days_warning,
      'days_critical'                => $days_critical,
      'contact'                      => $contact,
      'tags'                         => ['production','jenkins.io']
    },
    {
      'sitename'                     => 'accounts.jenkins.io',
      'url'                          => 'https://accounts.jenkins.io',
      'timeout'                      => $timeout,
      'treshold'                     => $treshold,
      'window'                       => $window,
      'collect_response_time'        => true,
      'check_certificate_expiration' => true,
      'days_warning'                 => $days_warning,
      'days_critical'                => $days_critical,
      'contact'                      => $contact,
      'tags'                         => ['production','jenkins.io']
    },
    {
      'sitename'                     => 'ci.jenkins.io',
      'url'                          => 'https://ci.jenkins.io',
      'timeout'                      => $timeout,
      'treshold'                     => $treshold,
      'window'                       => $window,
      'collect_response_time'        => true,
      'check_certificate_expiration' => true,
      'days_warning'                 => $days_warning,
      'days_critical'                => $days_critical,
      'contact'                      => $contact,
      'tags'                         => ['production','jenkins.io']
    },
    {
      'sitename'                     => 'pkg.jenkins.io',
      'url'                          => 'https://pkg.jenkins.io',
      'timeout'                      => $timeout,
      'treshold'                     => $treshold,
      'window'                       => $window,
      'collect_response_time'        => true,
      'check_certificate_expiration' => true,
      'days_warning'                 => $days_warning,
      'days_critical'                => $days_critical,
      'contact'                      => $contact,
      'tags'                         => ['production','jenkins.io']
    },
    {
      'sitename'                     => 'usage.jenkins.io',
      'url'                          => 'https://usage.jenkins.io',
      'timeout'                      => $timeout,
      'treshold'                     => $treshold,
      'window'                       => $window,
      'collect_response_time'        => true,
      'check_certificate_expiration' => true,
      'days_warning'                 => $days_warning,
      'days_critical'                => $days_critical,
      'contact'                      => $contact,
      'tags'                         => ['production','jenkins.io']
    },
    {
      'sitename'                     => 'updates.jenkins.io',
      'url'                          => 'https://updates.jenkins.io',
      'timeout'                      => $timeout,
      'treshold'                     => $treshold,
      'window'                       => $window,
      'collect_response_time'        => true,
      'check_certificate_expiration' => true,
      'days_warning'                 => $days_warning,
      'days_critical'                => $days_critical,
      'contact'                      => $contact,
      'tags'                         => ['production','jenkins.io']
    },
    {
      'sitename'                     => 'confluence',
      'url'                          => 'https://wiki.jenkins.io/display/JENKINS/Git+Plugin',
      'timeout'                      => $timeout,
      'treshold'                     => $treshold,
      'window'                       => $window,
      'collect_response_time'        => true,
      'check_certificate_expiration' => true,
      'days_warning'                 => $days_warning,
      'days_critical'                => $days_critical,
      'contact'                      => $contact,
      'tags'                         => ['production','jenkins.io']
    },
    {
      'sitename'                     => 'confluence backend',
      'url'                          => 'https://wiki.jenkins.io/s/2015/1/1/_/download/superbatch/css/batch.css',
      'timeout'                      => $timeout,
      'treshold'                     => $treshold,
      'window'                       => $window,
      'collect_response_time'        => true,
      'check_certificate_expiration' => true,
      'days_warning'                 => $days_warning,
      'days_critical'                => $days_critical,
      'contact'                      => $contact,
      'tags'                         => ['production','jenkins.io']
    },
    {
      'sitename'                     => 'jira',
      'url'                          => 'https://issues.jenkins-ci.org/browse/JENKINS-12345',
      'timeout'                      => $timeout,
      'treshold'                     => $treshold,
      'window'                       => $window,
      'collect_response_time'        => true,
      'check_certificate_expiration' => true,
      'days_warning'                 => $days_warning,
      'days_critical'                => $days_critical,
      'contact'                      => $contact,
      'tags'                         => ['production','jenkins-ci.org']
    }]
  }
}
