require 'spec_helper'


describe 'profile::kubernetes::reload' do
    let (:title) { 'datadog'}
    let (:params) do 
      {  
        'clusters' => [{
          'clustername' =>  'clusterexample1',
        }],
        'app'           => 'datadog',
        'depends_on'    => [
             "datadog/secret.yaml",
             "datadog/daemonset.yaml"
        ]
      }
    end

    it { should contain_class 'profile::kubernetes::params' }

    it { should contain_exec("reload datadog pods on clusterexample1").with(
        :command     => "kubectl delete pods -l app=datadog",
        :environment => ["KUBECONFIG=/home/k8s/.kube/clusterexample1.conf"],
        :path        => ["/home/k8s/.bin"],
        :logoutput   => true,
        :refreshonly => true,
        :subscribe   => [
            'Exec[update datadog/secret.yaml on clusterexample1]',
            'Exec[update datadog/daemonset.yaml on clusterexample1]'
        ]
      )
    }
  
end
