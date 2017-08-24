require 'spec_helper'


describe 'profile::kubernetes::apply' do
    let (:title) { 'nginx/deployment.yaml'}
    let (:facts) do
        {
            :path       => '/usr/bin'
        }
    end
    let (:params) do 
      {  
        'clusters' => [{
          'clustername' =>  'clusterexample1',
        }]
      }
    end

    it { should contain_class 'profile::kubernetes::params' }

    it { should contain_file("/home/k8s/resources/nginx/deployment.yaml").with(
      :owner  => 'k8s',
      :ensure => 'present'
      )
    }

    it { should contain_file("/home/k8s/trash/nginx.deployment.yaml").with(
      :ensure => 'absent'
      )
    }

    it { should contain_exec("update nginx/deployment.yaml on clusterexample1").with(
        :command     => "kubectl apply -f /home/k8s/resources/nginx/deployment.yaml",
        :environment => ["KUBECONFIG=/home/k8s/.kube/clusterexample1.conf"],
        :path        => ["/home/k8s/.bin",'/usr/bin'],
        :onlyif      => "test \"$(kubectl apply --dry-run -f /home/k8s/resources/nginx/deployment.yaml | grep configured)\""

      )
    }
    it { should contain_exec("init nginx/deployment.yaml on clusterexample1").with(
        :command     => "kubectl apply -f /home/k8s/resources/nginx/deployment.yaml",
        :environment => ["KUBECONFIG=/home/k8s/.kube/clusterexample1.conf"],
        :path        => ["/home/k8s/.bin", '/usr/bin'],
        :onlyif      => "test \"$(kubectl apply --dry-run -f /home/k8s/resources/nginx/deployment.yaml | grep created)\""

      )
    }
end
