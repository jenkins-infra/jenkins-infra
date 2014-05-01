# Jenkins Infra

[![Build
Status](https://jenkins.ci.cloudbees.com/buildStatus/icon?job=infra/jenkins-infra)](https://jenkins.ci.cloudbees.com/job/infra/job/jenkins-infra/)

This repository is the [r10k](https://github.com/adrienthebo/r10k) control
repository for the [Jenkins](https://jenkins-ci.org) project's own
infrastructure.

**NOTE:** This repository and workflow are still a **work in progress**

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

## Contributing

* `#jenkins-infra` on the [Freenode](http://freenode.net) IRC network
*  [INFRA project](https://issues.jenkins-ci.org/browse/INFRA) in JIRA.

