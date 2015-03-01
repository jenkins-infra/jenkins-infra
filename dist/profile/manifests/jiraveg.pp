# profile for jira
class profile::jiraveg (
  $jira_version,
  $jira_javahome,
  $jira_installdir,
  $jira_homedir,
  $jira_user,
  $jira_group,
  $jira_db,
  $jira_dbuser,
  $jira_dbpassword,
  $jira_dbname,
  $jira_dbport,
  $jira_dbdriver,
  $jira_dbtype,
  $jira_dbpoolsize,
){
  $pkgs = ['facter']
  package { $pkgs :
    ensure    => present
  } ->
  class { 'java':
    distribution  => 'jdk',
    package       => 'openjdk-7-jdk',
  } ->
  class { 'jira':
    version     => $jira_version,
    javahome    => $jira_javahome,
    installdir  => $jira_installdir,
    homedir     => $jira_homedir,
    user        => $jira_user,
    group       => $jira_group,

    # Database Settings
    db          => $jira_db,
    dbuser      => $jira_dbuser,
    dbpassword  => $jira_dbpassword,
    dbserver    => $jira_dbserver,
    dbname      => $jira_dname,
    dbport      => $jira_dbport,
    dbdriver    => $jira_dbdriver,
    dbtype      => $jira_dbtype,
    poolsize    => $jira_dbpoolsize,
  }

  class { 'jira::facts': }

}
