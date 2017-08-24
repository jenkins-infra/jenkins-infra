require_relative './../spec_helper'

describe 'kubernetes' do
  it_behaves_like "a standard Linux machine"

  describe user('k8s') do
    it { should exist }
  end

  describe file('/home/k8s/.bin') do
      it { should be_directory }
      it { should be_owned_by 'k8s' }
  end

  describe file('/home/k8s/.bin/kubectl') do
      it { should be_file }
      it { should be_owned_by 'k8s' }
      it { should be_readable } 
      it { should be_executable }
  end
  
  describe file('/home/k8s/resources') do
      it { should be_directory }
      it { should be_owned_by 'k8s' }
  end

  describe file('/home/k8s/.kube') do
      it { should be_directory }
      it { should be_owned_by 'k8s' }
  end

end
