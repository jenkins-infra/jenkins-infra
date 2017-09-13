require 'spec_helper'

describe 'profile::confluence' do
  it_behaves_like 'it has webserver firewall rules'

  it { should contain_class 'profile::atlassian' }
  it { should contain_class 'profile::apachemisc' }
  it { should contain_class 'profile::letsencrypt' }
  it { should contain_class 'apache::mod::headers' }
  it { should contain_class 'apache::mod::rewrite' }

  it { should contain_account('wiki').with(
    :home_dir => '/srv/wiki',
    :groups   => ['sudo', 'users'],
    :uid      => 2000,
    :gid      => 2000,
    :comment  => 'Runs confluence'
    )
  }

  it { should contain_class 'docker' }
  it { should contain_file '/srv/wiki/home' }
  it { should contain_file '/srv/wiki/docroot' }
  it { should contain_file '/srv/wiki/docroot/robots.txt' }
  it { should contain_file '/srv/wiki/container.env' }
  it { should contain_file '/var/log/apache2/wiki.jenkins-ci.org' }
  it { should contain_file '/var/log/apache2/wiki.jenkins.io' }
  it { should contain_service('docker-confluence') }

  it { should contain_apache__vhost('wiki.jenkins-ci.org non-ssl').with(
    :servername      => 'wiki.jenkins-ci.org',
    :port            => '80',
    :redirect_status => 'permanent',
    :redirect_dest   => 'https://wiki.jenkins.io/'
    )
  }
  it { should contain_apache__vhost('wiki.jenkins-ci.org').with(
    :servername      => 'wiki.jenkins-ci.org',
    :port            => '443',
    :redirect_status => 'permanent',
    :redirect_dest   => 'https://wiki.jenkins.io/'
    )
  }
  it { should contain_apache__vhost('wiki.jenkins.io non-ssl').with(
    :servername      => 'wiki.jenkins.io',
    :port            => '80',
    :redirect_status => 'permanent',
    :redirect_dest   => 'https://wiki.jenkins.io/'
    )
  }
  it { should contain_apache__vhost('wiki.jenkins.io')}

  it { should contain_firewall('299 allow synchrony for Confluence').with(
      :port   => 8091,
      :proto  => 'tcp',
      :action => 'accept'
    )
  }

  context 'environment => production' do
    let(:environment) { 'production' }

    it 'should obtain certificates' do
      expect(subject).to contain_letsencrypt__certonly('wiki.jenkins.io').with({
        :plugin => 'apache',
        :domains => ['wiki.jenkins.io', 'wiki.jenkins-ci.org'],
      })
    end
  end
end
