require 'spec_helper'


describe 'profile::kubernetes::reload' do
  let(:title) { 'datadog' }

  let(:facts) do
    {
      'path' => '/usr/bin'
    }
  end

  let(:params) do
    {
      'app' => 'datadog',
      'context' => 'minikube',
      'home' => '/home/k8s',
      'namespace' => 'default',
      'user' => 'k8s',
      'kubeconfig' => '/home/k8s/.kube/config',
      'depends_on' => [
        'datadog/secret.yaml',
        'datadog/daemonset.yaml'
      ]
    }
  end

  it { should contain_class 'profile::kubernetes::params' }

  it {
    should contain_exec('reload datadog pods on minikube')
      .with(
        'command' => 'kubectl delete pods --namespace default --context minikube -l app=datadog',
        'path' => ['/home/k8s/.bin', '/usr/bin'],
        'logoutput' => true,
        'refreshonly' => true,
        'subscribe' => [
          'Exec[update datadog/secret.yaml on minikube]',
          'Exec[update datadog/daemonset.yaml on minikube]'
        ]
      )
  }
end
