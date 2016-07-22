#
# Catchall virtualhosts for the legacy jenkins-ci.org domain
class profile::catchall(
  $docroot = '/var/www/html',
) {
  include ::apache
  include profile::apachemisc

  $apache_log_dir = '/var/log/apache2/jenkins-ci.org'
  $apache_maven_log_dir = '/var/log/apache2/maven.jenkins-ci.org'
  $apache_stats_log_dir = '/var/log/apache2/stats.jenkins-ci.org'
  $docroot_user = 'www-data'

  file { [$apache_maven_log_dir, $apache_log_dir, $apache_stats_log_dir] :
    ensure => directory,
  }

  file { $docroot :
    ensure => directory,
    owner  => $docroot_user,
  }

  file { "${docroot}/jenkins.jnlp" :
    ensure  => present,
    source  => "puppet:///modules/${module_name}/catchall/jenkins.jnlp",
    owner   => $docroot_user,
    mode    => '0755',
    require => File[$docroot],
  }

  apache::vhost { 'jenkins-ci.org':
    docroot         => $docroot,
    port            => 443,
    ssl             => true,
    ssl_key         => '/etc/apache2/legacy_cert.key',
    ssl_chain       => '/etc/apache2/legacy_chain.crt',
    ssl_cert        => '/etc/apache2/legacy_cert.crt',
    override        => ['All'],
    error_log_file  => 'jenkins-ci.org/error.log',
    access_log_pipe => "|/usr/bin/rotatelogs ${apache_log_dir}/access.log.%Y%m%d%H%M%S 604800",
    # Using a big custom fragment here because our ordering of redirects and
    # aliases is actually fairly important and it's difficult to ensure order
    # in any other way
    custom_fragment => '
  AddType    application/x-java-jnlp-file jnlp

  # compatibility with old package repository locations
  RedirectMatch ^/redhat/(.*) https://pkg.jenkins.io/redhat/$1
  RedirectMatch ^/opensuse/(.*) https://pkg.jenkins.io/opensuse/$1
  RedirectMatch ^/debian/(.*) https://pkg.jenkins.io/debian/$1
  # convenient short URLs
  RedirectMatch /issue/(.+)          https://issues.jenkins-ci.org/browse/JENKINS-$1
  RedirectMatch /commit/core/(.+)    https://github.com/jenkinsci/jenkins/commit/$1
  RedirectMatch /commit/(.+)/(.+)    https://github.com/jenkinsci/$1/commit/$2
  RedirectMatch /pull/(.+)/([0-9]+)  https://github.com/jenkinsci/$1/pull/$2

  Redirect /maven-site/hudson-core /maven-site/jenkins-core

  # https://issues.jenkins-ci.org/browse/INFRA-351
  RedirectMatch ^/maven-hpi-plugin(.*) http://jenkinsci.github.io/maven-hpi-plugin/$1

  # Probably not needed but, rating code moved a while ago
  RedirectMatch ^/rate/(.*) https://rating.jenkins.io/$1
  RedirectMatch ^/census/(.*) https://census.jenkins.io/$1
  Redirect /jenkins-ci.org.key https://pkg.jenkins.io/redhat/jenkins.io.key

  # permalinks
  # - this one is referenced from 1.395.1 "sign post" release
  Redirect /why            https://wiki.jenkins-ci.org/pages/viewpage.action?pageId=53608972
  # baked in the help file to create account on Oracle for JDK downloads
  Redirect /oracleAccountSignup    http://www.oracle.com/webapps/redirect/signon?nexturl=http://jenkins-ci.org/
  # to the donation page
  Redirect /donate        https://wiki.jenkins-ci.org/display/JENKINS/Donation
  # CLA links used in the CLA forms
  Redirect /license        https://wiki.jenkins-ci.org/display/JENKINS/Governance+Document#GovernanceDocument-cla
  Redirect /licenses        https://wiki.jenkins-ci.org/display/JENKINS/Governance+Document#GovernanceDocument-cla
  # used to advertise the project meeting
  Redirect /meetings/        https://wiki.jenkins-ci.org/display/JENKINS/Governance+Meeting+Agenda
  # used from friends of Jenkins plugin to link to the thank you page
  Redirect /friend        https://wiki.jenkins-ci.org/display/JENKINS/Donation
  # used by Gradle JPI plugin to include fragment
  Redirect /gradle-jpi-plugin/latest    https://raw.github.com/jenkinsci/gradle-jpi-plugin/master/install
  # used when encouraging people to subscribe to security advisories
  Redirect /advisories        https://wiki.jenkins-ci.org/display/JENKINS/Security+Advisories
  # used in slides and handouts to refer to survey
  Redirect /survey        http://s.zoomerang.com/s/JenkinsSurvey
  # used by RekeySecretAdminMonitor in Jenkins
  Redirect /rekey            https://wiki.jenkins-ci.org/display/SECURITY/Re-keying
  # persistent Google hangout link
  Redirect /hangout        https://plus.google.com/hangouts/_/event/cjh74ltrnc8a8r2e3dbqlfnie38
# .16.203.43 repo.jenkins-ci.org
  Redirect /pull-request-greeting    https://wiki.jenkins-ci.org/display/JENKINS/Pull+Request+to+Repositories
  # Mailer plugin uses this to redirect to Javamail javadoc page
  Redirect /javamail-properties   https://javamail.java.net/nonav/docs/api/overview-summary.html#overview_description
  # baked in jenkins.war 1.587 / 1.580.1
  Redirect /security-144          https://wiki.jenkins-ci.org/display/JENKINS/Slave+To+Master+Access+Control
  # baked in 1.600 easter egg
  Redirect /100k                  https://jenkins.io/content/jenkins-celebration-day-february-26

  RedirectMatch permanent ^/((?!patron|maven-site|jenkins.jnlp).+)$ https://jenkins.io/$1
',
    require         => [
      File['/etc/apache2/legacy_cert.key'],
      File[$apache_log_dir],
    ],
  }

  apache::vhost { 'jenkins-ci.org unsecured':
    servername      => 'jenkins-ci.org',
    serveraliases   => [
      'www.jenkins-ci.org',
    ],
    docroot         => $docroot,
    port            => 80,
    redirect_status => 'permanent',
    redirect_dest   => 'https://jenkins-ci.org/',
    override        => ['All'],
    error_log_file  => 'jenkins-ci.org/error_nonssl.log',
    access_log_pipe => "|/usr/bin/rotatelogs ${apache_log_dir}/access_nonssl.log.%Y%m%d%H%M%S 604800",
    require         => File[$docroot],
  }

  apache::vhost { 'maven.jenkins-ci.org' :
    port            => 80,
    docroot         => $docroot,
    custom_fragment => '
  RedirectMatch ^/content/repositories/releases/(.*) http://repo.jenkins-ci.org/releases/$1
  RedirectMatch ^/content/repositories/snapshots/(.*) http://repo.jenkins-ci.org/snapshots/$1
',
    error_log_file  => 'maven.jenkins-ci.org/error_nonssl.log',
    access_log_pipe => "|/usr/bin/rotatelogs ${apache_maven_log_dir}/access.log.%Y%m%d%H%M%S 604800",
    require         => [
      File[$docroot],
      File[$apache_maven_log_dir],
    ],
  }

  apache::vhost { 'stats.jenkins-ci.org' :
    docroot         => $docroot,
    port            => 80,
    redirect_status => 'permanent',
    redirect_dest   => 'http://stats.jenkins.io/',
    override        => ['All'],
    error_log_file  => 'stats.jenkins-ci.org/error_nonssl.log',
    access_log_pipe => "|/usr/bin/rotatelogs ${apache_stats_log_dir}/access_nonssl.log.%Y%m%d%H%M%S 604800",
    require         => [
      File[$docroot],
      File[$apache_stats_log_dir],
    ],
  }

  # Legacy update site compatibility
  ##################################
  file { '/etc/apache2/legacy_cert.key':
    ensure  => present,
    content => hiera('ssl_legacy_key'),
    require => Package['httpd'],
  }

  file { '/etc/apache2/legacy_chain.crt':
    ensure  => present,
    content => hiera('ssl_legacy_chain'),
    require => Package['httpd'],
  }

  file { '/etc/apache2/legacy_cert.crt':
    ensure  => present,
    content => hiera('ssl_legacy_cert'),
    require => Package['httpd'],
  }
  ##################################
}
