# Generates the apache virtual host config file for the maintenance mode
#
# This puts a file under /etc/apache2/sites-available/SITENAME.maintenance
# and you can manually symlink this from sites-enabled to put the maintenance mode UI
define profile::apache-maintenance {
  # $name refers to the site name

  # Template uses: $addr_port
  file { '/var/www/maintenance':
    ensure => directory,
  }

  file { '/var/www/maintenance/maintenance.html':
    ensure => present,
    source => "puppet:///modules/${module_name}/apache-maintenance/maintenance.html",
  }

  file { "/etc/apache2/sites-available/${name}.maintenance.conf":
    ensure  => present,
    content => template("${module_name}/apache-maintenance/maintenance.conf.erb"),
  }
}
