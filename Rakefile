require 'puppet-lint/tasks/puppet-lint'
require 'puppetlabs_spec_helper/rake_tasks'

PuppetLint.configuration.send('disable_140chars')

desc "Validate the Puppet syntax of all manifests"
task :validate do
  Dir['./{dist,manifests}/**/*.pp'].each do |filename|
    sh "puppet parser validate --parser future '#{filename}'"
  end
end

PuppetLint::RakeTask.new :lint do |config|
  config.disable_checks = ['80chars',
                           'class_parameter_defaults',
                           'names_containing_dash']
  config.pattern = 'dist/**/*.pp'
  config.fail_on_warnings = true
end

desc 'Resolve all the dependencies'
task :resolve do
  # for reasons beyond me, we list dependencies in Puppetfile and .fixtures.yml
  # we need to keep them in sync, and when we change them we need to run two commands
  # to reflect those changes

  # this fills ./modules
  `rm -rf ./modules/*`
  `r10k puppetfile install`

  # this fills ./spec/fixtures/modules
  Rake::Task['spec_clean'].invoke
  Rake::Task['spec_prep'].invoke
end
