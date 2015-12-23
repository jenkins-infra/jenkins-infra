#
# The staticsite profile ensures that the right resources are present to host
# the jenkins.io static site.
#
# context: <https://issues.jenkins-ci.org/browse/INFRA-506>
class profile::staticsite(
  $site_root = '/srv/jenkins.io',
  $deployer_user = 'site-deployer',
  $deployer_ssh_key = undef,
) {
  include apache
  # The apache-misc profile includes a number of other important monitoring and
  # apache configuration settings
  include profile::apache-misc

  validate_string($deployer_user)
  validate_string($deployer_ssh_key)
  validate_absolute_path($site_root)

  ensure_packages(['zip'])

  # This shell is very important to ensure that this user cannot do much else
  # other than upload some data
  $deployer_shell = '/usr/lib/sftp-server'
  $deployer_group = 'www-data'
  $site_docroot = "${site_root}/current"

  account { $deployer_user:
    home_dir     => $site_root,
    ssh_key      => $deployer_ssh_key,
    gid          => $deployer_group,
    create_group => false,
    shell        => $deployer_shell,
    comment      => 'Static Site Deployer role account',
    notify       => Exec['chown staticsite'],
  }


  # Make sure our deployer's shell is listed as a valid shell
  file_line { 'sftp-server shell':
    path => '/etc/shells',
    line => $deployer_shell,
  }

  file { "${site_root}/archives":
    ensure  => directory,
    mode    => '0644',
    owner   => $deployer_user,
    group   => $deployer_group,
    require => Account[$deployer_user],
    notify  => Exec['chown staticsite'],
  }

  # The deploy-site script ensures that we can unzip an archive properly, it
  # does not ensure that the archive gets placed in the appropriate location on
  # the machine
  file { "${site_root}/deploy-site":
    ensure  => present,
    owner   => $deployer_user,
    group   => $deployer_group,
    mode    => '0700',
    source  => "puppet:///modules/${module_name}/staticsite/deploy-site",
    require => Account[$deployer_user],
  }

  # To simplify permissions and keep the site-deployer's shell restricted to
  # just SFTP, the `deploy-site` script is idempotent and can be run repeatedly
  # without any issue
  cron { 'deploy-site':
    ensure  => present,
    user    => $deployer_user,
    command => "${site_root}/deploy-site",
    minute  => '*',
    require => File["${site_root}/deploy-site"],
  }


  # Setting up this symlink ahead of time even though archives/ isn't the right
  # place for it to go. This prevents apache::vhost from making current/ a
  # directory
  file { $site_docroot:
    ensure  => link,
    replace => false,
    owner   => $deployer_user,
    group   => $deployer_group,
    target  => "${site_root}/archives",
    require => File["${site_root}/archives"],
  }

  exec { 'chown staticsite':
    command     => "/bin/chown -R ${deployer_user}:${deployer_group} ${site_root}",
    refreshonly => true,
  }

  apache::vhost { ['beta.jenkins-ci.org', 'beta.jenkins.io']:
    port    => '80',
    docroot => $site_docroot,
    require => File[$site_docroot],
  }
}
