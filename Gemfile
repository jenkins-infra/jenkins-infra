source 'https://rubygems.org'

gem 'rake'
gem 'rspec-puppet'
gem 'puppet-lint'
gem 'puppet', '~> 3.4.0'

group :development do
  # XXX: Shouldn't be needed anywhere by rtyler's machine, since Vagrant does'nt
  # have proper installers for FreeBSD :(
  gem 'vagrant', :github => 'mitchellh/vagrant', :ref => 'v1.5.4'
end

# Vagrant plugins
group :plugins do
  gem 'vagrant-aws', :github => 'mitchellh/vagrant-aws'
end
