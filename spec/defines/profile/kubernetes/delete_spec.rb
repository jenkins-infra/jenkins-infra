require 'spec_helper'


describe 'profile::kubernetes::delete' do
    let (:title) { 'nginx/deployment.yaml'}
    let (:params) do 
      {  
        'clusters' => [{
          'clustername' =>  'clusterexample1',
        }]
      }
    end

    it { should contain_class 'profile::kubernetes::params' }

    it { should contain_file("/home/k8s/trash/nginx.deployment.yaml").with(
      :owner  => 'k8s',
      :ensure => 'present'
      )
    }

    it { should contain_exec("Remove nginx/deployment.yaml on clusterexample1").with(
        :command     => "kubectl delete --grace-period=60 --ignore-not-found=true -f /home/k8s/trash/nginx.deployment.yaml",
        :environment => ["KUBECONFIG=/home/k8s/.kube/clusterexample1.conf"],
        :path        => ["/home/k8s/.bin", :undef],
        :onlyif      => "test \"$(kubectl apply --dry-run=true -f /home/k8s/trash/nginx.deployment.yaml | grep configured)\""

      )
    }
  
    it { should contain_file("/home/k8s/resources/nginx/deployment.yaml").with(
      :ensure => 'absent'

      )
    }

end
