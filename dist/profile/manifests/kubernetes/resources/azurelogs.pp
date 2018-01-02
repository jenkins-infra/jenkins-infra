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
  String $context = '',
  String $storage_account_name = '',
  String $storage_account_key = '',
  String $loganalytics_key = '',
  String $loganalytics_workspace_id = '',
  Array $clusters = $profile::kubernetes::params::clusters
) inherits profile::kubernetes::params {

  include ::stdlib
  require profile::kubernetes::kubectl


  $clusters.each | $cluster | {
    $context = $cluster['clustername']

    file { "${profile::kubernetes::params::resources}/${context}/azurelogs":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    profile::kubernetes::apply { "azurelogs/secret.yaml on ${context}":
      context    => $context,
      parameters => {
        'storage_account_name'      => base64('encode', $storage_account_name, 'strict'),
        'storage_account_key'       => base64('encode', $storage_account_key, 'strict'),
        'loganalytics_key'          => base64('encode', $loganalytics_key, 'strict'),
        'loganalytics_workspace_id' => base64('encode', $loganalytics_workspace_id, 'strict')
      },
      resource   => 'azurelogs/secret.yaml'
    }
  }
}
