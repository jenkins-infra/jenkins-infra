#   Class: profile::kubernetes::resources::ldap
#
#   This class deploys the Jenkins Ldap on Kubernetes
#
#   Parameters:
#
#   Remark:
#     `kubectl get service nginx --namespace nginx-ingress` return service public ip
#     This public ip should be used for DNS record frontend_url -> this IP
#     In order to create letsencrypt certificates
#
# Deploy ldap resources on kubernetes cluster
class profile::kubernetes::resources::ldap (
    Array $clusters = $profile::kubernetes::params::clusters,
    Array $whitelisted_sources = [
      '10.0.0.0/8'
    ],
    String $ca_tls_crt = '',
    String $ca_tls_crt_filename = 'cacert.pem',
    String $image_tag = '',
    String $ldap_admin_password = 's3cr3t',
    String $ldap_tls_crt = 'test',
    String $ldap_tls_key = 'test',
    String $ldap_tls_crt_filename = 'cert.pem',
    String $ldap_tls_key_filename = 'privkey.key',
    String $openldap_admin_dn = 'cn=admin,dc=jenkins-ci,dc=org',
    String $openldap_database = 'dc=jenkins-ci,dc=org',
    String $openldap_debug_level = '256',
    String $openldap_backup_path = '/var/backups',
    String $openldap_data_path = '/var/lib/ldap',
    String $storage_account_key = '',
    String $storage_account_name = '',
  ) inherits profile::kubernetes::params {
  require profile::kubernetes::kubectl
  require profile::kubernetes::resources::nginx
  require profile::kubernetes::resources::lego

  $clusters.each | $cluster| {
    $context = $cluster['clustername']
    # Only set field loadBalancerIp if a publicIp is provided

    if has_key($cluster,'ldap_public_ip'){
      $public_ip = $cluster['ldap_public_ip']
    }
    else{
      $public_ip = 'none'
    }

    file { "${profile::kubernetes::params::resources}/${context}/ldap":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    profile::kubernetes::apply { "ldap/namespace.yaml on ${context}":
      context  => $context,
      resource => 'ldap/namespace.yaml',
    }

    profile::kubernetes::apply { "ldap/persistentVolume-backup.yaml on ${context}":
      context  => $context,
      resource => 'ldap/persistentVolume-backup.yaml',
    }

    profile::kubernetes::apply { "ldap/persistentVolumeClaim-backup.yaml on ${context}":
      context  => $context,
      resource => 'ldap/persistentVolumeClaim-backup.yaml',
    }

    profile::kubernetes::apply { "ldap/persistentVolumeClaim-data.yaml on ${context}":
      context  => $context,
      resource => 'ldap/persistentVolumeClaim-data.yaml',
    }

    profile::kubernetes::apply { "ldap/service.yaml on ${context}":
      context    => $context,
      resource   => 'ldap/service.yaml',
      parameters => {
        whitelisted_sources => $whitelisted_sources,
        loadBalancerIp      => $public_ip
      }
    }

    profile::kubernetes::apply { "ldap/secret.yaml on ${context}":
      context    => $context,
      resource   => 'ldap/secret.yaml',
      parameters => {
        'storage_account_key'  => base64('encode', $storage_account_key, 'strict'),
        'storage_account_name' => base64('encode', $storage_account_name, 'strict'),
        'ldap_admin_password'  => base64('encode', $ldap_admin_password, 'strict'),
        'ldap_tls_crt'         => base64('encode', $ldap_tls_crt, 'strict'),
        'ldap_tls_key'         => base64('encode', $ldap_tls_key, 'strict'),
        'ca_tls_crt'           => base64('encode', $ca_tls_crt, 'strict'),
      }
    }

    profile::kubernetes::apply { "ldap/stateful.yaml on ${context}":
      context    => $context,
      resource   => 'ldap/stateful.yaml',
      parameters => {
        'image_tag'             => $image_tag,
        'openldap_admin_dn'     => $openldap_admin_dn,
        'openldap_database'     => $openldap_database,
        'openldap_debug_level'  => $openldap_debug_level,
        'openldap_backup_path'  => $openldap_backup_path,
        'openldap_data_path'    => $openldap_data_path,
        'ldap_tls_crt_filename' => $ldap_tls_crt_filename,
        'ldap_tls_key_filename' => $ldap_tls_key_filename,
        'ca_tls_crt_filename'   => $ca_tls_crt_filename,
      }
    }

    profile::kubernetes::reload { "ldap pods on ${context}":
      app        => 'ldap',
      context    => $context,
      depends_on => [
        'ldap/secret.yaml',
        'ldap/persistentVolume-backup.yaml',
        'ldap/persistentVolumeClaim-backup.yaml',
        'ldap/persistentVolumeClaim-data.yaml'
      ],
      namespace  => 'ldap'
    }

  }
}
