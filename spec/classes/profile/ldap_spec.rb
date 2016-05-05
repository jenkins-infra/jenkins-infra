require 'spec_helper'

describe 'profile::ldap' do
  it { should contain_class 'firewall' }
  it { should contain_package('libaugeas-ruby') }

  context 'ldap configuration and setup' do
    it { should contain_class 'openldap::server' }
    it { should contain_package 'slapd' }
    it { should contain_service('slapd').with_ensure(:running) }

    context "slapd's configuration" do
      it 'should enable non-SSL LDAP on localhost only' do
        expect(subject).to contain_class('openldap::server').with({
          :ldap_ifs => ['127.0.0.1'],
        })
      end

      it 'should enable SSL LDAP' do
        expect(subject).to contain_class('openldap::server').with({
          :ldaps_ifs => ['/'],
        })
      end

      it 'should enable LDAP on a local unix socket' do
        expect(subject).to contain_class('openldap::server').with({
          :ldapi_ifs => ['/'],
        })
      end

      it 'should no longer manage a defaults file' do
        # This is handled by camptocamp/openldap now
        expect(subject).not_to contain_file('/etc/default/slapd')
      end
    end

    context 'with a provided paramaters` parameter' do
      let(:password) { 'rspec-ldap' }
      let(:ldap_db) { 'dc=rspec' }
      let(:admin_dn) { 'cn=admin' }
      let(:params) do
        {
          :database => ldap_db,
          :admin_dn => admin_dn,
          :admin_password => password,
        }
      end

      it 'should contain a correct openlda::server::database configuration' do
        expect(subject).to contain_openldap__server__database(ldap_db).with({
          :directory => '/var/lib/ldap',
          :rootdn => admin_dn,
          :rootpw => password,
        })
      end

      it 'should contain write access for the admin user' do
        acl_rule = "to attrs=userPassword,shadowLastChange by dn=\"#{admin_dn}\" on #{ldap_db}"
        expect(subject).to contain_openldap__server__access(acl_rule).with({
          :access => 'write',
        })
      end

      it 'should allow anonymous users to authenticate' do
        acl_rule = "to attrs=userPassword,shadowLastChange by anonymous on #{ldap_db}"
        expect(subject).to contain_openldap__server__access(acl_rule).with({
          :access => 'auth',
        })
      end

      it 'should allow users to modify themselves' do
        acl_rule = "to attrs=userPassword,shadowLastChange by self on #{ldap_db}"
        expect(subject).to contain_openldap__server__access(acl_rule).with({
          :access => 'write',
        })
      end

      it 'should deny everything else' do
        acl_rule = "to attrs=userPassword,shadowLastChange by * on #{ldap_db}"
        expect(subject).to contain_openldap__server__access(acl_rule).with({
          :access => 'none',
        })
      end
    end

    context 'ldap indices' do
      ['cn', 'mail', 'surname', 'givenname', 'ou'].each do |attr|
        it "should index `#{attr}`" do
          expect(subject).to contain_openldap__server__dbindex("#{attr} index").with({
            :attribute => attr,
            :indices => 'eq,pres,sub',
          })
        end
      end

      it 'should index `uniqueMember`' do
        expect(subject).to contain_openldap__server__dbindex('uniqueMember index').with({
          :attribute => 'uniqueMember',
          :indices => 'eq',
        })
      end
    end
  end

  context 'monitoring' do
    it { should contain_class 'datadog_agent' }
    it { should contain_profile__datadog_check 'ldap-process-check' }
  end
end
