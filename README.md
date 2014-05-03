# Jenkins Infra

[![Build
Status](https://jenkins.ci.cloudbees.com/buildStatus/icon?job=infra/jenkins-infra)](https://jenkins.ci.cloudbees.com/job/infra/job/jenkins-infra/)

This repository is the [r10k](https://github.com/adrienthebo/r10k) control
repository for the [Jenkins](https://jenkins-ci.org) project's own
infrastructure.

**NOTE:** This repository and workflow are still a **work in progress**

## Local development

The amount of testing that can be done locally is still a **work in progress**
but thus far it's advisable that you do the following:

 * `bundle install` - To get the necessary gems to run tests locally, if you're
   unfamiliar with Ruby development you may want to use [RVM](http://rvm.io/)
   to create an isolated Ruby environment
 * `bundle exec rake spec lint` - Will run the
   [rspec-puppet](http://rspec-puppet) unit tests and the
   [puppet-lint](http://puppet-lint.com) style validation. If you intend to run
   the rspec-puppet over and over, use `rake spec_standalone` to avoid
   re-initializing the Puppet module fixtures every time.

### Vagrant-based testing

#### Pre-requisites

 * Import your SSH public key into a [key
   pair](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
   into the `us-west-2` region. We have an AMI in us-west-2 that has Ubuntu 12.04,
   Puppet and a Docker-capable kernel installed for testing
 * Make sure your `default` [security
   group](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html)
   allows SSH (port 22) from the outside world.
 * Run the `./vagrant-bootstrap` script locally to make usre your local
   environment is prepared for Vagranting

#### Running server spec tests

We're using [serverspec](http://serverspec.org) for on-machine acceptance
testing. Combined with Vagrant, this allows us to create an acceptance test
[per-role](dist/role/manifests) which
provisions and tests an entire Puppet catalog on a VM.



## Branching model

The default branch of this repository is `staging` which is where pull requests
should be applied to by default.


```

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

For installing agents refer to the [installing agents](http://docs.puppetlabs.com/pe/latest/install_basic.html#installing-agents) section of the PuppetLabs documentation.

## Contributing

* `#jenkins-infra` on the [Freenode](http://freenode.net) IRC network
*  [INFRA project](https://issues.jenkins-ci.org/browse/INFRA) in JIRA.
* [infra@lists.jenkins-ci.org](http://lists.jenkins-ci.org/mailman/listinfo/jenkins-infra)

