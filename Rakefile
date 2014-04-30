require 'puppet-lint/tasks/puppet-lint'

PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.ignore_paths = ["modules/**/*.pp"]

desc "Validate the Puppet syntax of all manifests"
task :validate do
  Dir['./**/*.pp'].each do |filename|
    sh "puppet parser validate '#{filename}'"
  end
end
