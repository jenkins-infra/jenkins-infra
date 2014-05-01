require 'puppet-lint'
require 'puppetlabs_spec_helper/rake_tasks'


PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.ignore_paths = ['modules/**/*.pp', 'spec/fixtures/**/*.pp']
PuppetLint.configuration.fail_on_warnings = true

desc "Validate the Puppet syntax of all manifests"
task :validate do
  Dir['./{dist,manifests}/**/*.pp'].each do |filename|
    sh "puppet parser validate '#{filename}'"
  end
end
