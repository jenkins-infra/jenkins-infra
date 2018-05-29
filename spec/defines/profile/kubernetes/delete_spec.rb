require 'spec_helper'

describe 'profile::kubernetes::delete' do
  let(:title) { 'nginx/deployment.yaml' }

  let(:facts) do
    {
      'path' => '/usr/bin'
    }
  end

  let(:params) do
    {
      'context'    => 'minikube',
      'resource'   => 'nginx/deployment.yaml',
      'home'       => '/home/k8s',
      'user'       => 'k8s',
      'kubeconfig' => '/home/k8s/.kube/config'
    }
  end

  it { should contain_class 'profile::kubernetes::params' }

  it {
    should contain_file('/home/k8s/trash/minikube.nginx.deployment.yaml')
      .with(
        'owner'  => 'k8s',
        'ensure' => 'present'
      )
  }

  delete_args = [
    '--context minikube ',
    '--grace-period=60 ',
    '--ignore-not-found=true ',
    '-f /home/k8s/trash/minikube.nginx.deployment.yaml'
  ].join

  apply_args = [
    '--context minikube ',
    '--dry-run ',
    '-f /home/k8s/trash/minikube.nginx.deployment.yaml'
  ].join

  it {
    should contain_exec('Remove nginx/deployment.yaml on minikube')
      .with(
        'command' => "kubectl delete #{delete_args}",
        'path'    => ['/home/k8s/.bin', '/usr/bin'],
        'onlyif'  => "test \"$(kubectl apply #{apply_args} | grep configured)\""
      )
  }

  it {
    should contain_file('/home/k8s/resources/minikube/nginx/deployment.yaml')
      .with(
        'ensure' => 'absent'
      )
  }
end
