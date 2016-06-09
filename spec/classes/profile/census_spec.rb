require 'spec_helper'

describe 'profile::census' do
  it { should contain_class 'profile::apachemisc' }
  it { should contain_class 'lvm' }
  it { should contain_class 'apache' }

  it_behaves_like 'it has webserver firewall rules'

  it { should contain_package('httpd').with(:name => 'apache2') }
  it { should contain_apache__vhost 'census.jenkins.io' }

  it 'should have the usage public key in authorized keys' do
    expect(subject).to contain_ssh_authorized_key('usage').with({
      :user => 'census',
      :type => 'ssh-rsa',
    })
  end

  it 'should manage the docroot under the user home_dir' do
    expect(subject).to contain_file('/srv/census/census').with({
      :ensure => :directory,
      :owner => 'census',
      :mode => '0755',
    })
  end
end


describe 'profile::census::agent' do
  let(:params) do
    {
      :user => 'jenkins',
      :home_dir => '/var/lib/jenkins',
    }
  end

  it { should contain_class 'profile::census::agent' }
  it { should contain_class 'stdlib' }

  it 'should have the usage private key' do
    expect(subject).to contain_file("#{params[:home_dir]}/.ssh/usage").with({
      :ensure => :file,
      :owner => params[:user],
      :mode => '0600',
    })
  end

  it 'should have the usage public key' do
    expect(subject).to contain_ssh_authorized_key('usage').with({
      :user => params[:user],
      :type => 'ssh-rsa',
    })
  end
end
