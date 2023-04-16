require 'spec_helper'

describe 'profile::buildagent' do

  context 'SSH host keys' do
    it "should include GitHub's host keys" do
      properties = {
        :host_aliases => ['github.com'],
        :ensure => :present,
      }
      expect(subject).to contain_sshkey('github-rsa').with(properties)
    end
  end

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
    it { expect(subject).to contain_user 'jenkins' }
    it { expect(subject).to contain_group 'jenkins' }

    # Needed for updating ulimits
    it { expect(subject).to contain_class 'limits' }
  end

  context 'with docker => true' do
    it { expect(subject).to contain_class 'docker' }
    it { expect(subject).to contain_package 'docker' }

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
      it { expect(subject).to contain_file('/home/jenkins/.docker/config.json').with_ensure('absent') }
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

  context 'on Linux' do
    it { expect(subject).to contain_package 'subversion' }
    it { expect(subject).to contain_package 'make' }
    it { expect(subject).to contain_package 'build-essential' }
    it { expect(subject).to contain_package 'tar' }
    it { expect(subject).to contain_package 'git' }
    it { expect(subject).to contain_package 'unzip' }

    # All JDKs
    it { expect(subject).to contain_file '/opt/jdk-8' }
    it { expect(subject).to contain_file '/opt/jdk-11' }
    it { expect(subject).to contain_file '/opt/jdk-17' }
  end

  context 'with ssh_private_keys' do
    let(:home) { '/tmp/rspec' }
    let(:private_keys) do
      {
        "#{home}/.ssh/special" => {
          'privkey'  => 'specialprivatekey',
          'for_host' => 'updates.jenkins.io',
        },
      }
    end
    let(:params) do
      {
        :home_dir => home,
        :private_ssh_keys => private_keys,
      }
    end

    it 'should install the special private key' do
      expect(subject).to contain_file("#{home}/.ssh/special").with({
        :ensure => :present,
        :content => 'specialprivatekey',
      })
    end

    it 'should update ~/.ssh/config for the special private key' do
      expect(subject).to contain_ssh__client__config__user('jenkins').with({
        :ensure => :present,
      })
    end
  end
end
