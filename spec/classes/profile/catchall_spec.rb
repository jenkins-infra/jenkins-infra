require 'spec_helper'

describe 'profile::catchall' do
  let(:docroot) { '/tmp/rspecdocroot' }
  let(:params) do
    {
      :docroot => docroot,
    }
  end

  it { should contain_class 'profile::catchall' }
  it { should contain_class 'apache' }

  it { should contain_file(docroot).with_ensure(:directory) }
  # https://issues.jenkins-ci.org/browse/INFRA-639
  it 'should install jenkins.jnlp' do
    expect(subject).to contain_file("#{docroot}/jenkins.jnlp").with({
      :ensure => :present,
      :owner => 'www-data',
      :mode => '0755',
    })
  end

  ['legacy_cert.key', 'legacy_chain.crt', 'legacy_cert.crt'].each do |f|
    it { should contain_file("/etc/apache2/#{f}").with_ensure(:present) }
  end

  context 'Apache VirtualHosts' do
    context 'HTTPs VirtualHost' do
      let(:name) { 'jenkins-ci.org' }
      it { should contain_apache__vhost(name) }

      it 'should be configured to serve over HTTPs' do
        expect(subject).to contain_apache__vhost(name).with({
          :port => 443,
          :ssl => true,
          :ssl_key   => '/etc/apache2/legacy_cert.key',
          :ssl_chain => '/etc/apache2/legacy_chain.crt',
          :ssl_cert  => '/etc/apache2/legacy_cert.crt',
        })
      end
    end


    context 'HTTP VirtualHost' do
      let(:name) { 'jenkins-ci.org unsecured' }
      it { should contain_apache__vhost(name) }

      it 'should be configured to promote to a HTTPs request' do
        expect(subject).to contain_apache__vhost(name).with({
          :port => 80,
          :redirect_status => 'permanent',
          :redirect_dest => 'https://jenkins-ci.org/',
        })
      end
    end

    it { pending 'INFRA-868'; should contain_apache__vhost('stats.jenkins-ci.org') }
  end
end
