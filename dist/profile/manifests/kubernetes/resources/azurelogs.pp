# Provide azure secret for everything related to logs on kubernetes
#   Class: profile::kubernetes::resources::azurelogs
#
#   This class deploy secrets for azure, related to logs
#
#   Parameters:
#     $storage_account_name:$loganalytics_workspace_id
#       Define storage account name used to store logs
#
#     $storage_account_key:
#       Define storage account key used to authenticate on $storage_account_name 
#
#     $loganalytics_workspace_id: 
#       Define azure log analytics workspace id
#
#     $loganalytics_key:
#       Define azure log analytics key related to $loganalytics_workspace_id

class profile::kubernetes::resources::azurelogs (
  String $storage_account_name = '',
  String $storage_account_key = '',
  String $loganalytics_key = '',
  String $loganalytics_workspace_id = ''
){

  include ::stdlib
  include profile::kubernetes::params
  include profile::kubernetes::kubectl

  file { "${profile::kubernetes::params::resources}/azurelogs":
    ensure => 'directory',
    owner  => $profile::kubernetes::params::user,
  }

  profile::kubernetes::apply { 'azurelogs/secret.yaml':
    parameters => {
      'storage_account_name'      => base64('encode', $storage_account_name, 'strict'),
      'storage_account_key'       => base64('encode', $storage_account_key, 'strict'),
      'loganalytics_key'          => base64('encode', $loganalytics_key, 'strict'),
      'loganalytics_workspace_id' => base64('encode', $loganalytics_workspace_id, 'strict')
    }
  }
}
