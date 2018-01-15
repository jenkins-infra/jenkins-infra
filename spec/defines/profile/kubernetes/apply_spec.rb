require 'spec_helper'

describe 'profile::kubernetes::apply' do
  let(:title) { 'nginx/deployment.yaml on minikube' }
  let(:facts) do
    {
      'path' => '/usr/bin'
    }
  end
  let(:params) do
    {
      'resource' => 'nginx/deployment.yaml',
      'context' => 'minikube',
      'user' => 'k8s',
      'kubeconfig' => '/home/k8s/.kube/config'
    }
  end

  args = [
    '--context minikube ',
    '-f /home/k8s/resources/minikube/nginx/deployment.yaml'
  ].join

  it { should contain_class 'profile::kubernetes::params' }

  it {
    should contain_file('/home/k8s/resources/minikube/nginx/deployment.yaml')
      .with(
        'owner'  => 'k8s',
        'ensure' => 'present'
      )
  }

  it {
    should contain_file('/home/k8s/trash/minikube.nginx.deployment.yaml')
      .with(
        'ensure' => 'absent'
      )
  }

  it {
    should contain_exec('update nginx/deployment.yaml on minikube')
      .with(
        'command' => "kubectl apply #{args}",
        'path'    => ['/home/k8s/.bin', '/usr/bin'],
        'onlyif'  => "test \"$(kubectl apply --dry-run #{args} | grep configured)\""
      )
  }
  it {
    should contain_exec('init nginx/deployment.yaml on minikube')
      .with(
        'command' => "kubectl apply #{args}",
        'path' => ['/home/k8s/.bin', '/usr/bin'],
        'onlyif' => "test \"$(kubectl apply --dry-run #{args} | grep created)\""
      )
  }
end
