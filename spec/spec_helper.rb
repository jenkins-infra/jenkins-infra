require 'rubygems'
require 'rspec'
require 'pry'

RSpec.configure do |c|
  c.mock_with :rspec
end
require 'puppetlabs_spec_helper/module_spec_helper'

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

  # Use the `facter` command on any production node to see real-life values
  c.default_facts = {
    :os => {
      :architecture => 'amd64',
      :distro => {
        :codename => "bionic",
        :description => "Ubuntu 18.04.6 LTS",
        :id => "Ubuntu",
        :release => {
          :full => "18.04",
          :major => "18.04"
        },
      },
      :family => "Debian",
      :hardware => "x86_64",
      :name => "Ubuntu",
      :release => {
        :full => "18.04",
        :major => "18.04"
      },
      :selinux => {
        :enabled => false
      }
    },
    #####
    # Mocked facts required by the r10k puppet module
    :processors => {
      :count => 2,
    },
    :ruby => {
      :version => '2.6.10',
    },
    ####
    # Legacy facts, hidden by default from default facter output.
    # Call the `facter` command with the fact name as argument to view it: 'facter operatingsystemrelease'
    :osfamily => 'Debian',
    :kernel => 'Linux',
    :lsbdistid => 'Ubuntu',
    :lsbdistrelease => '18.04',
    :lsbdistcodename => 'bionic',
    :operatingsystem => 'Ubuntu',
    :operatingsystemrelease => '18.04',
    ####
    :concat_basedir => '/tmp',
    :is_pe => true,
    # Needed for conditionals like:
    # <https://github.com/saz/puppet-sudo/blob/v3.0.6/manifests/init.pp#L147>
    # Get versions matrix at https://puppet.com/docs/puppet/7/platform_lifecycle.html#about_agent-platform-releases
    :puppetversion => '6.28.0',
    :facterversion => '3.14.24', # Must be the version installed with the puppet-agent package
    :pe_version => '6.27.1',
    :pe_server_version => '2019.8.11',
    :apt_update_last_success => '1657469796',
    :vagrant => false,
    :staging_http_get => 'curl',
  }
end
