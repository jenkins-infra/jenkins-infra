require 'rubygems'
require 'pry'
require 'puppetlabs_spec_helper/module_spec_helper'

FIXTURES_PATH = File.expand_path(File.dirname(__FILE__) + '/fixtures')
# Set up our $LOAD_PATH to properly include custom provider code from modules
# in spec/fixtures
$LOAD_PATH.unshift(*Dir["#{FIXTURES_PATH}/modules/*/lib"])

RSpec.configure do |c|
  c.hiera_config = File.join(FIXTURES_PATH, 'hiera.yaml')
  c.default_facts = {
    :osfamily => 'Debian',
  }
  c.mock_with :rspec
end
