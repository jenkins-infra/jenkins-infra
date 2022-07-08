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
  # Cleanup
  `rm -rf ./modules/ .fixtures.yml`

  # Generate the test fixtures from the Puppetfile and install them in ./spec/fixtures/ (modules, symlinks, etc.)
  `generate-puppetfile -p ./Puppetfile --fixtures-only --ignore-comments`
  # Remove jenkins_keys as it is a private repository
  `yq --inplace 'del(.fixtures.repositories.jenkins_keys)' .fixtures.yml # Remove jenkins_keys as it is a private repository`

  # this fills ./spec/fixtures/modules
  Rake::Task['spec_clean'].invoke
  Rake::Task['spec_prep'].invoke
end
