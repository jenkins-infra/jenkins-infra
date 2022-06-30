# Jenkins Infra

[![Build Status](https://ci.jenkins.io/buildStatus/icon?job=Infra/jenkins-infra/production)](https://ci.jenkins.io/job/Infra/job/jenkins-infra/job/production/)

This repository is the [r10k](https://github.com/adrienthebo/r10k) control
repository for the [Jenkins](https://jenkins.io) project's own
infrastructure.

## Structure

See the [Jenkins infrastructure project](https://jenkins.io/projects/infrastructure/) for overview of the project's infrastructure and the services being managed by this repository.
A non exhaustive list of services is available [here](https://jenkins.io/projects/infrastructure/#services).

### Implementation notes

* The services are managed [r10k](https://github.com/adrienthebo/r10k) and Puppet,
  configuration files are available inside this repository.
* There are multiple types of service deployments:
  * The majority of services run as containers inside Kubernetes, and are NOT managed here (ref. jenkins-infra/charts)
  * Some services like ci.jenkins.io run inside virtual machines provisioned in cloud providers
  * the other services are running on bare metal machines provided by sponsors
* There are Puppet templates for all services.
  Configuration options are defined by Hiera and stored in [hieradata](./hieradata).
  See [hieradata/common.yaml](./hieradata/common.yaml) for the most of the settings.
* Not all services are fully configured with Configuration-as-Code.
  For example, Jenkins masters ([buildmaster template](./dist/profile/manifests/buildmaster.pp)) rely on configurations being supplied from Jenkins home directories.

### Containerized services

All containerized services are stored in separate repositories ([Plugin Site](https://plugins.jenkins.io/), [IRC Bot](https://jenkins.io/projects/infrastructure/ircbot/), etc.).
They have their own release cycles and maintainers.
This repo just manages and configures the deployments.

* See [this page](https://jenkins.io/projects/infrastructure/#services) for service repository links.
* Service images are hosted inside the [jenkinsciinfra DockerHub account](https://hub.docker.com/r/jenkinsciinfra/).
* Usually there is a Continuous Delivery pipeline configured for services inside their repositories.
* Image versions are defined in the [hieradata/common.yaml](./hieradata/common.yaml) file by the `*:image_tag` variables.
  Services can be updated by submitting a pull request with the version update.

## Local development

The amount of testing that can be done locally is as follows:

* `bundle install` - To get the necessary gems to run tests locally, if you're
  unfamiliar with Ruby development you may want to use [RVM](http://rvm.io/)
  to create an isolated Ruby environment
* `./check` - Will run the
  [rspec-puppet](http://rspec-puppet) unit tests and the
  [puppet-lint](http://puppet-lint.com) style validation. If you intend to run
  the rspec-puppet over and over, use `rake spec_standalone` to avoid
  re-initializing the Puppet module fixtures every time.

### Vagrant-based testing

#### Running server spec tests

We're using [serverspec](http://serverspec.org) for on-machine acceptance
testing. Combined with Vagrant, this allows us to create an acceptance test
[per-role](dist/role/manifests) which provisions and tests an entire Puppet
catalog on a VM.

##### Pre-requisites for Vagrant

* Install [Vagrant](https://www.vagrantup.com)
<!-- * Install Vagrant plugins: `vagrant plugin install vagrant-serverspec` -->
* Run the `./vagrant-bootstrap` script locally to make sure your local
  environment is prepared for Vagranting

To launch a test instance, `vagrant up ROLE` where `ROLE` is [one of the defined roles](dist/role/manifests).
You can rerun puppet and execute tests with `vagrant provision ROLE` repeatedly while the VM is up and running.
<!-- To just rerun serverspect without puppet, `vagrant provision --provision-with serverspec ROLE`.
When it's all done, deprovision the instance via `vagrant destroy ROLE`. -->

### Updating dependencies

For reasons that Tyler will hopefully clarify at some point, this module maintains
the list of Puppet module dependencies in `Puppetfile` and `.fixtures.yml`. They
need to be kept in sync. When you modify them, you can have the local environment
reflect changes by running `bundle exec rake resolve`.

## Branching model

The default branch of this repository is `staging` which is where pull requests
should be applied to by default.

```text

+----------------+
| pull-request-1 |
+-----------x----+
             \
              \ (review and merge, runs acceptance tests)
staging        \
|---------------o--x--x--x---------------->
                          \
                           \ (manual merge, auto-deploys to prod hosts)
production                  \
|----------------------------o------------->
```

The branching model is a little different than what you might be familiar with.
We merge pull requests into a special branch called `staging` where we can run
Puppet acceptance tests from. Once somebody has code reviewed a pull request it
can be merged into `staging`.

When a infra project team member is happy with the code in `staging` they can
create a merge from `staging` to `production`. Once something has been merged
to production, it will be automatically deployed to production hosts.

## Installing agents

For installing agents refer to the [installing
agents](http://docs.puppetlabs.com/pe/latest/install_agents.html) section of
the PuppetLabs documentation.

## Adding a new branch/environment

"Dynamic environments" are in a bit of flux for the current version (3.7) of
Puppet Enterprise that we're using. An unfortunate side-effect of this is that
creating a branch in this repository is *not* sufficient to create a dynamic
environment that can be used via the Puppet master.

The enable an environment, add a file on the Puppet master:
`/etc/puppetlabs/puppet/environments/my-environment-here/environment.conf` with
the following:

```conf
modulepath = ./dist:./modules:/opt/puppet/share/puppet/modules
manifest = ./manifests/site.pp
```

## Contributing

See [this page](https://github.com/jenkins-infra/.github/blob/master/CONTRIBUTING.md) for the overview and links.

Channels:

* `#jenkins-infra` on the [Freenode](http://freenode.net) IRC network
* [INFRA project](https://issues.jenkins-ci.org/browse/INFRA) in JIRA.
* [infra@lists.jenkins-ci.org](http://lists.jenkins-ci.org/mailman/listinfo/jenkins-infra)
