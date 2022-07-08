source 'https://rubygems.org'

gem 'rake'
gem 'rspec-puppet'
gem 'parallel_tests'
# Needed for integration tests
gem 'beaker'
# This gem is like, never released
gem 'puppet-lint', '~>2.3.0'
gem 'puppet', '~> 4.8'
# Needed to make sure we can install modules and then run a `puppet apply` in
# vagrant
gem 'r10k'
gem 'puppetlabs_spec_helper'
gem 'pry'
gem 'serverspec'
gem 'hiera-eyaml', '~>3.2.2'
gem 'generate-puppetfile'

group :development do
  gem 'debugger', :platform => :mri_19
  gem 'debugger-pry', :platform => :mri_19
  gem 'byebug', :platform => :mri_20
end

gem "rspec_junit_formatter"
