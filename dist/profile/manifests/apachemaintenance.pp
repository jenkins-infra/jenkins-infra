# Generates the apache virtual host config file for the maintenance mode
#
# This puts a file under /etc/apache2/sites-available/SITENAME.maintenance
# and you can manually symlink this from sites-enabled to put the maintenance mode UI
define profile::apachemaintenance {
  # $name refers to the site name

  # Template uses: $addr_port
  file { '/var/www/maintenance':
    ensure => directory,
  }

  file { '/var/www/maintenance/maintenance.html':
    ensure => file,
    source => "puppet:///modules/${module_name}/apachemaintenance/maintenance.html",
  }

  file { "/etc/apache2/sites-available/${name}.maintenance.conf":
    ensure  => file,
    content => template("${module_name}/apachemaintenance/maintenance.conf.erb"),
  }
}
