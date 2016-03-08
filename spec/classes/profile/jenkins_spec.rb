require 'spec_helper'

describe 'profile::jenkins' do
  context 'firewall rules' do
    it { should contain_class 'profile::firewall' }

    it 'should have a CLI port rule' do
      expect(subject).to contain_firewall('108 Jenkins CLI port').with({
        :port => 47278,
        :action => :accept,
      })
    end

    it 'should ensure nothing talks directly to Jenkins' do
      expect(subject).to contain_firewall('801 Allow Jenkins web access only on localhost').with({
        :port => 8080,
        :action => :accept,
        :iniface => 'lo',
      })

      expect(subject).to contain_firewall('802 Block external Jenkins web access').with({
        :port => 8080,
        :action => :drop,
      })

    end

    it 'should allow CLI SSH on 22222' do
      expect(subject).to contain_firewall('810 Jenkins CLI SSH').with({
        :port => 22222,
        :action => :accept,
      })
    end
  end
end
