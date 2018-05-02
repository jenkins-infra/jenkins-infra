require 'spec_helper'

describe 'profile::kubernetes::resources::ldap' do
  let(:params) do
    {
      'image_tag'             => 'latest'
    }
  end

  it { should contain_class('profile::kubernetes::kubectl') }
  it { should contain_class('profile::kubernetes::resources::lego') }
  it { should contain_class('profile::kubernetes::resources::nginx') }

  it {
    should contain_file('/home/k8s/resources/minikube/ldap').with(
      'ensure' => 'directory',
      'owner'  => 'k8s'
    )
  }

  it {
    should contain_profile__kubernetes__apply('ldap/service.yaml on minikube')
  }

  it {
    should contain_profile__kubernetes__apply('ldap/namespace.yaml on minikube')
  }

  it {
    should contain_profile__kubernetes__apply(
      'ldap/persistentVolume-backup.yaml on minikube'
    )
  }

  it {
    should contain_profile__kubernetes__apply(
      'ldap/persistentVolumeClaim-data.yaml on minikube'
    )
  }

  it {
    should contain_profile__kubernetes__apply(
      'ldap/persistentVolumeClaim-backup.yaml on minikube'
    )
  }

  it {
    should contain_profile__kubernetes__apply(
      'ldap/stateful.yaml on minikube'
    ).with(
      'context'    => 'minikube',
      'parameters' => {
        'image_tag' => 'latest',
        'openldap_admin_dn'     => 'cn=admin,dc=jenkins-ci,dc=org',
        'openldap_database'     => 'dc=jenkins-ci,dc=org',
        'openldap_debug_level'  => '256',
        'openldap_backup_path'  => '/var/backups',
        'openldap_data_path'    => '/var/lib/ldap',
        'ldap_tls_crt_filename' => 'cert.pem',
        'ldap_tls_key_filename' => 'privkey.key',
        'ca_tls_crt_filename'   => 'cacert.pem'
      }
    )
  }

  it {
    should contain_profile__kubernetes__apply(
      'ldap/secret.yaml on minikube'
    )
  }

  it { should contain_profile__kubernetes__reload('ldap pods on minikube') }
end
