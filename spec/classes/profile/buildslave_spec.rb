require 'spec_helper'

describe 'profile::buildslave' do
  context 'SSH host keys' do
    it "should include GitHub's host keys" do
      properties = {
        :host_aliases => ['github.com'],
        :ensure => :present,
      }
      expect(subject).to contain_sshkey('github-rsa').with(properties)
    end
  end

  # Provided by the `git` module
  it { should contain_package 'git' }

  context 'managing a `jenkins` user' do
    it 'should provision the "jenkins" account properly' do
      expect(subject).to contain_account('jenkins').with({
        # We need our docker group to exist first, which is provided by the
        # package
        :require => 'Package[docker]',
      })
      expect(subject).to contain_package('docker')
    end

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

  context 'with docker => true' do
    it { should contain_class 'docker' }
    it { should contain_package 'docker' }

    it 'the `jenkins` user should be in the `docker` group' do
      expect(subject).to contain_user('jenkins').with({
        :groups => ['jenkins', 'docker'],
      })
    end

    context 'with trusted_agent => true' do
      let(:params) { { :trusted_agent => true } }
      it 'should contain dockerhub credentials' do
        expect(subject).to contain_file('/home/jenkins/.docker').with_ensure('directory')
        expect(subject).to contain_file('/home/jenkins/.docker/config.json').with_ensure('file')
      end
    end

    context 'with trusted_agent => false' do
      let(:params) { { :trusted_agent => false } }
      it { should contain_file('/home/jenkins/.docker/config.json').with_ensure('absent') }
    end
  end

  context 'with docker => false' do
    let(:params) do
      {
        :docker => false,
      }
    end

    it { should_not contain_class 'profile::docker' }

    it 'should not provision ~/.docker' do
      expect(subject).to_not contain_file('/home/jenkins/.docker')
    end

    it 'should not include `docker` in the `jenkins` user groups' do
      expect(subject).to contain_user('jenkins').with({
        :groups => ['jenkins'],
      })
    end

    it 'should not require Package[docker] for the `jenkins` account' do
      # We cannot use the #without_require matcher here because it doesn't play
      # nicely with undefs:
      #   expected that the catalogue would contain Account[jenkins] with require
      #   not set to "Package[docker]" but it is set to nil
      expect(subject).to contain_account('jenkins').with_require(nil)
    end
  end

  context 'with ruby => true' do
    it { should contain_class 'ruby' }
    it { should contain_package 'bundler' }
    it { should contain_package 'libruby' }
  end

  context 'with ruby => false' do
    let(:params) do
      {
        :ruby => false,
      }
    end

    it { should_not contain_class 'ruby' }
    it { should_not contain_package 'bundler' }
    it { should_not contain_package 'libruby' }
  end


  context 'on Linux' do
    it { should contain_package 'subversion' }
    it { should contain_package 'make' }
    it { should contain_package 'build-essential' }
  end

  context 'on Darwin' do
    let(:facts) do
      {
        :kernel => 'Darwin',
      }
    end

    it { should_not contain_package 'build-essential' }
  end
end
