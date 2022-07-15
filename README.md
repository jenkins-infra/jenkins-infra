# Jenkins Infra

This repository hosts the Puppet code for the [Jenkins](https://jenkins.io) project's own infrastructure.

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
  For example, Jenkins controllers ([jenkinscontroller profile](./dist/profile/manifests/jenkinscontroller.pp)) rely on configurations being supplied from Jenkins home directories.

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

### Pre-requisites for Local Development

* Ruby 2.6.x is required.
  * Please note that Ruby 2.7.x and 3.x have never been tested.
* Bundler 1.17.x is required with the command line `bundle` installed and present in your `PATH`.
  * Please note that Bundler 2.x had never been tested
* A bash-compliant shell is required.
  * `sh` has never been tested, neither Windows Cygwin Shell (but WSL is ok).
* The command line `yq` in version 4.x is needed

You can **always** check the Docker image that ci.jenkins.io uses to run the test harness for this project at <https://github.com/jenkins-infra/docker-inbound-agents/blob/main/ruby/Dockerfile> (Jenkins agent labelled with `ruby`).

### Install Local Dependencies

Run the script `./script/setupgems.sh` to ensure that all the local dependencies are ready for local development, including:

* Ruby Gems managed by `bundler` (through `Gemfile` and `Gemfile.lock`) to ensure development tools are available through `bundle exec <tool>` commands, installed to `vendor/gems`
* Puppet modules retrieved from `./Puppetfile` and installed to `./modules`
* Unit Tests fixtures generated from `./Puppetfile` into `.fixtures.yml` but also other locations in `./spec/`

### Vagrant-based testing

#### Running Acceptance Tests

TL;DR: As for today, there are no automated acceptance tests. Contributions are welcome.

A long time ago, this repository used [serverspec](http://serverspec.org) for on-machine acceptance testing.
Combined with Vagrant, it allowed to execute acceptance tests [per-role](dist/role/manifests).

But this serverspec with Vagrant uses deprecated (and not maintained anymore) components.

Proposal for the future:

* Switch to [Goss](https://github.com/aelsabbahy/goss) as it can also be used for [Docker with the `dgoss` wrapper](https://github.com/aelsabbahy/goss/tree/master/extras/dgoss) and provides automatic adding tests
* ServerSpec V2 executed through `vagrant ssh` (but requires updating ruby dependencies + find a way to run serverspec within the VM instead of outside)

##### Pre-requisites for Vagrant

* Make sure that you have set up all the [Pre-requisites for local development](#pre-requisites-for-local-development) above
* Install [Vagrant](https://www.vagrantup.com) version 2.x.
* Install [Docker](https://www.docker.com/)
  * Docker Desktop is recommended but any other Docker Engine installation should work.
  * Only Linux containers are supported, with Cgroups v2. (CGroups v1 *might* work).
  * The command line `docker` must be present in your `PATH`.
  * You must be able to share a local directory and to use the flag `--privileged`.
* Run the `./scripts/vagrant-bootstrap.sh` script to prepare your local environment.

To launch a test instance, `vagrant up ROLE` where `ROLE` is [one of the defined roles in "dist/role/manifests"/](dist/role/manifests").

Ex: `vagrant up jenkins::controller`

You can re-run puppet and execute tests with `vagrant provision ROLE` repeatedly while the VM is up and running.
When it's all done, remove the instance the instance via `vagrant destroy ROLE`.

## Branching model

The default branch of this repository is `production` which is where pull requests should be applied to by default.

```text

+----------------+
| pull-request-1 |
+-----------x----+
             \
              \ (review and merge, runs tests)
production     \
|---------------o--x--x--x---------------->
```

When a infra project team member is happy with the code in your pull request, they can merge it to production, which will be automatically deployed to production hosts.

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

* `#jenkins-infra` on the [Libera Chat](https://libera.chat/guides) IRC network - see <https://www.jenkins.io/chat/>
* [jenkins-infra/helpdesk Issue Tracker](https://github.com/jenkins-infra/helpdesk) in GitHub.
* [jenkins-infra@groups.google.com](https://groups.google.com/g/jenkins-infra) mailing list
