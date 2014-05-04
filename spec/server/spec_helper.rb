require_relative './../spec_helper'

# Server spec requirements!
require 'serverspec'
require 'pathname'
require 'net/ssh'
# Including these at a top level to make sure we have some methods for our DSL
# that we need for server spec
include SpecInfra::Helper::Ssh
include SpecInfra::Helper::DetectOS

# Load all our helpful support files
support_dir = File.expand_path(File.dirname(__FILE__) + '/support')
Dir["#{support_dir}/**/*.rb"].each do |f|
  require f
end
