require 'spec_helper'

describe 'profile::buildslave' do
  it { should contain_class 'ruby' }

  context 'SSH host keys' do
    it "should include GitHub's host keys" do
      properties = {
        :host_aliases => ['github.com'],
        :ensure => :present,
      }
      expect(subject).to contain_sshkey('github-rsa').with(properties)
    end
  end

  context 'build slave tooling' do
    it { should contain_package 'bundler' }
    # Provided by the `git` module
    it { should contain_package 'git' }
    it { should contain_package 'subversion' }

    it { should contain_package 'make' }
    it { should contain_package 'build-essential' }
  end

  context 'managing a `jenkins` user' do
    it { should contain_account 'jenkins' }

    # Keeping these two examples here to make sure a user and group are created
    it { should contain_user 'jenkins' }
    it { should contain_group 'jenkins' }

    context 'ssh keys' do
      it 'should provision the private node sync private key' do
        expect(subject).to contain_file('/home/jenkins/.ssh/id_rsa').with({
          :ensure => 'file',
        })
      end
    end
  end

  context 'docker support' do
    it { should contain_class 'docker' }
    it { should contain_package 'docker' }

    it 'should contain dockerhub credentials' do
      expect(subject).to contain_file('/home/jenkins/.docker').with_ensure('directory')

      expect(subject).to contain_file('/home/jenkins/.docker/config.json').with_ensure('file')
    end
  end
end
