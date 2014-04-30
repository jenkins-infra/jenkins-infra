require 'rubygems'
require 'pry'
require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |c|
  c.hiera_config = File.expand_path(File.dirname(__FILE__) + '/fixtures/hiera.yaml')
  c.default_facts = {
    :osfamily => 'Debian',
  }
  c.mock_with :rspec
end
