require 'spec_helper'

describe 'profile::kubernetes::resources::kube_state_metrics' do
  let (:params) do
    {
        :image_tag     => 'latest'
    }
  end
  it { should contain_class('profile::kubernetes::params') }
  it { should contain_class('profile::kubernetes::kubectl') }

  it { should contain_file("/home/k8s/resources/kube_state_metrics").with(
    :ensure => 'directory',
    :owner  => 'k8s'
    )
  }
  it { should contain_profile__kubernetes__apply('kube_state_metrics/service.yaml')}
  it { should contain_profile__kubernetes__apply('kube_state_metrics/deployment.yaml').with(
    :parameters => {
      'image_tag' => 'latest'
      }
    )

  }
end
