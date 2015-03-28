#
# SSL certificates
#
class profile::ssl-cert (
  # all injected from hiera
  $id,        # identify which private key / certificate pair we should use. This usually comes from hieradata/clients/*.yaml
) {
  include apache

  # certificates and apache config to let Apache recognize this file
  file { '/etc/apache2/certificate.crt':
    source => "puppet:///modules/${module_name}/ssl-cert/${id}.crt",
    notify => Service['httpd'],
  }
  file { '/etc/apache2/bundle.crt':
    source => "puppet:///modules/${module_name}/ssl-cert/${id}-bundle.crt",
    notify => Service['httpd'],
  }
  file { '/etc/apache2/conf.d/ssl.conf':
    source => "puppet:///modules/${module_name}/ssl-cert/ssl.conf",
    notify => Service['httpd'],
  }

  file { '/etc/apache2/server.key':
    content => hiera("profile::ssl-cert::secret-key-${id}"),
    mode    => '0600',
    notify  => Service['httpd'],
  }
}