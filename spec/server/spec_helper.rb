# Server spec requirements!
require 'serverspec'
require 'pathname'
require 'net/ssh'

set :backend, :ssh

# Load all our helpful support files
support_dir = File.expand_path(File.dirname(__FILE__) + '/support')
Dir["#{support_dir}/**/*.rb"].each do |f|
  require f
end
