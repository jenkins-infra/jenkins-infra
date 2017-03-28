require_relative './../spec_helper'

describe 'Resources Nginx' do
    describe file('/home/k8s/resources/nginx') do
        it { should be_directory }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
    end
    describe file('/home/k8s/resources/nginx/namespace.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'Namespace')
        }
    end
    describe file('/home/k8s/resources/nginx/configmap.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'ConfigMap')
        }
    end
    describe file('/home/k8s/resources/nginx/deployment.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'Deployment')
        }
    end
    describe file('/home/k8s/resources/nginx/default-deployment.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'Deployment')
        }
    end
    describe file('/home/k8s/resources/nginx/service.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'Service')
        }
    end
    describe file('/home/k8s/resources/nginx/default-service.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'Service')
        }
    end
end
