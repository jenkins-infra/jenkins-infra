require 'rubygems'
require 'rspec'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'pry'

FIXTURES_PATH = File.expand_path(File.dirname(__FILE__) + '/fixtures')
# Set up our $LOAD_PATH to properly include custom provider code from modules
# in spec/fixtures
$LOAD_PATH.unshift(*Dir["#{FIXTURES_PATH}/modules/*/lib"])

Dir[File.absolute_path(File.dirname(__FILE__) + '/support/*.rb')].each do |f|
  require f
end

RSpec.configure do |c|
  c.mock_with :rspec
  c.formatter = :documentation

  c.manifest = File.join(File.dirname(__FILE__), '..',  'manifests', 'site.pp')

  c.hiera_config = File.join(FIXTURES_PATH, 'hiera.yaml')

  c.default_facts = {
    :architecture => 'amd64',
    :osfamily => 'Debian',
    :kernel => 'Linux',
    :lsbdistid => 'Ubuntu',
    :lsbdistrelease => '18.04',
    :lsbdistcodename => 'bionic',
    :operatingsystem => 'Ubuntu',
    :operatingsystemrelease => '18.04',
    :concat_basedir => '/tmp',
    :is_pe => true,
    # Needed for conditionals like:
    # <https://github.com/saz/puppet-sudo/blob/v3.0.6/manifests/init.pp#L147>
    :puppetversion => '6.0.4',
    :pe_version => '6.0.4',
    :pe_server_version => '2019.0.1',
  }
  c.before(:each) do
    # Workaround until this is fixed:
    #   <https://tickets.puppetlabs.com/browse/PUP-1547>
    require 'puppet/confine/exists'
    Puppet::Confine::Exists.any_instance.stubs(:which => '')
  end


end
