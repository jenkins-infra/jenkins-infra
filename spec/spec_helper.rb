require 'rubygems'
require 'rspec'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'pry'

FIXTURES_PATH = File.expand_path(File.dirname(__FILE__) + '/fixtures')
# Set up our $LOAD_PATH to properly include custom provider code from modules
# in spec/fixtures
$LOAD_PATH.unshift(*Dir["#{FIXTURES_PATH}/modules/*/lib"])


RSpec.configure do |c|
  c.mock_with :rspec
  # Use color in STDOUT
  c.color_enabled = true
  c.formatter = :documentation

  c.hiera_config = File.join(FIXTURES_PATH, 'hiera.yaml')
  c.default_facts = {
    :osfamily => 'Debian',
    :lsbdistid => 'Ubuntu',
    :operatingsystemrelease => '12.04',
    :concat_basedir => '/tmp'
  }

  c.before(:each) do
    # Workaround until this is fixed:
    #   <https://tickets.puppetlabs.com/browse/PUP-1547>
    require 'puppet/confine/exists'
    Puppet::Confine::Exists.any_instance.stubs(:which => '')
  end
end
