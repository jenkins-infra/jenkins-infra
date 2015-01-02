# profile for jira
class profile::jiraveg (
  $jira_javahome,
  $jira_version
){
  $pkgs = ['openjdk-7-jre-headless', 'facter']
  package { $pkgs :
    ensure    => present
  } ->
  class { 'jira':
    version     => $jira_version,
    javahome    => $jira_javahome,
    installdir  => '/opt/jira',
    homedir     => '/srv/jira_home',
    user        => 'jira_user',
    group       => 'jira',

    # Database Settings
    db          => 'postgresql',
    dbuser      => 'jiraadm',
    dbpassword  => 'mypassword',
    dbserver    => 'localhost',
    dbname      => 'jira',
    dbport      => '5432',
    dbdriver    => 'org.postgresql.Driver',
    dbtype      => 'postgres72',
    poolsize    => '20',
  }

  class { 'jira::facts': }

}
