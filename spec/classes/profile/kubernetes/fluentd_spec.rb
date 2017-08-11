require 'spec_helper'

describe 'profile::kubernetes::resources::fluentd' do
  let(:params) do
      {
          :image_tag => 'FFFFFF',
      }
  end

  it { should contain_class('profile::kubernetes::params') }
  it { should contain_class('profile::kubernetes::kubectl') }
  it { should contain_file("/home/k8s/resources/fluentd").with(
    :ensure => 'directory',
    :owner  => 'k8s'
    )
  }
  it { should contain_profile__kubernetes__apply('fluentd/daemonset.yaml').with(
    :parameters => { 
        'image_tag' => 'FFFFFF'
      }
    )
  }

  it { should contain_profile__kubernetes__reload('fluentd pods')}
end
