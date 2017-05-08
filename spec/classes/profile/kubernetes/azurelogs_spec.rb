require 'spec_helper'

describe 'profile::kubernetes::resources::azurelogs' do
  let(:params) do
      {
          :storage_account_name      => 'storage_account_name',
          :storage_account_key       => 'storage_account_key',
          :loganalytics_key          => 'loganalytics_key',
          :loganalytics_workspace_id => 'workspace_id'
      }
  end

  it { should contain_class('stdlib')}
  it { should contain_class('profile::kubernetes::params') }
  it { should contain_class('profile::kubernetes::kubectl') }
  it { should contain_file("/home/k8s/resources/azurelogs").with(
    :ensure => 'directory',
    :owner  => 'k8s'
    )
  }
  it { should contain_profile__kubernetes__apply('azurelogs/secret.yaml').with({
    :parameters => { 
        'storage_account_name'      => 'c3RvcmFnZV9hY2NvdW50X25hbWU=',
        'storage_account_key'       => 'c3RvcmFnZV9hY2NvdW50X2tleQ==',
        'loganalytics_key'          => 'bG9nYW5hbHl0aWNzX2tleQ==',
        'loganalytics_workspace_id' => 'd29ya3NwYWNlX2lk'
      }
    })
  }
end
