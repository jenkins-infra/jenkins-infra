source 'https://rubygems.org'

gem 'rake'
gem 'rspec-puppet'
gem 'parallel_tests'
# Needed for integration tests
gem 'beaker'
# This gem is like, never released
gem 'puppet-lint', :github => 'rodjek/puppet-lint', :ref => '2546fed6be894bbcff15c3f48d4b6f6bc15d94d1'
gem 'puppet', '~> 3.4.0'
# Needed to make sure we can install modules and then run a `puppet apply` in
# vagrant
gem 'r10k'
gem 'puppetlabs_spec_helper'
gem 'pry'
gem 'serverspec'
gem 'hiera-eyaml'

group :development do
  gem 'debugger', :platform => :mri_19
  gem 'debugger-pry', :platform => :mri_19
  gem 'byebug', :platform => :mri_20
end
