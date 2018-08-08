require 'spec_helper'

describe 'profile::catchall' do
  let(:docroot) { '/tmp/rspecdocroot' }
  let(:params) do
    {
      'docroot' => docroot
    }
  end

  it { should contain_class 'profile::catchall' }
  it { should contain_class 'apache' }

  it { should contain_file(docroot).with_ensure(:absent) }
  # https://issues.jenkins-ci.org/browse/INFRA-639
  it 'should not install jenkins.jnlp' do
    expect(subject).to contain_file("#{docroot}/jenkins.jnlp").with(
      'ensure' => 'absent'
    )
  end

  ['legacy_cert.key', 'legacy_chain.crt', 'legacy_cert.crt'].each do |f|
    it { should contain_file("/etc/apache2/#{f}").with_ensure(:absent) }
  end

  context 'Apache VirtualHosts' do
    context 'HTTPs VirtualHost' do
      let(:name) { 'jenkins-ci.org' }
      it { should contain_apache__vhost(name) }

      it 'should not be configured to serve over HTTPs' do
        expect(subject).to contain_apache__vhost(name).with(
          'ensure' => 'absent'
        )
      end
    end

    context 'HTTP VirtualHost' do
      let(:name) { 'jenkins-ci.org unsecured' }
      it { should contain_apache__vhost(name) }

      it 'should not be configured to promote to a HTTPs request' do
        expect(subject).to contain_apache__vhost(name).with(
          'ensure' => 'absent'
        )
      end
    end

    # Legacy vhosts which I hope can perish at some point
    # See INFRA-639
    it {
      should contain_apache__vhost('stats.jenkins-ci.org').with(
        'ensure' => 'absent'
      )
    }
    it {
      should contain_apache__vhost('maven.jenkins-ci.org').with(
        'ensure' => 'absent'
      )
    }
  end
end
