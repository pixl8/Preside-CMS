---
id: branchingmodel
title: Our git branching model and release strategy
---

We use the [TwGit flow](https://github.com/Twenga/twgit) by [Twenga](http://twgit.twenga.com/) to manage our software releases. What this means is that the repository will always have a branch named `stable` and this will contain the very latest official release. Official releases will also be tagged using [Semantic Versioning](http://semver.org/).

Upcoming releases that we're working on will have their own release branch that will live until the release has been finalized and merged into `stable`. The naming convention for these branches is `release-x.x.x` where `x.x.x` is the proposed release version number.

Individual changes are all made in their own *feature* branches that are merged into the *release* branch when they're ready to be tested with the upcoming release. The naming convention for these branches is `feature-JIRA-XXX_shortdescription`, where `JIRA-XXX` is the JIRA issue number that is being worked on.

## Packaged builds

Whenever we push changes to the GitHub repository, we have [Travis CI](https://travis-ci.org/) run our test suite (the [test results](http://downloads.presidecms.com/#!/presidecms%2Ftestresults%2F) are posted to our downloads site). In addition, we also have Travis create a packaged zip file of the system when the branch being pushed is a *release* branch, or when we push a *tag*.

Builds of tagged releases make it to the ["release" folder on our downloads site](http://downloads.presidecms.com/#!/presidecms%2Frelease%2F). Builds of upcoming release branches make it the the ["bleeding-edge" folder on our downloads site](http://downloads.presidecms.com/#!/presidecms%2Fbleeding-edge%2F).

## What this means for you

For the most part, you don't really have to worry about this branching model. If you're contributing code changes, [[submittingchanges|our guide to contributing changes]], should give you all you need to know.

That said, if you *are* pulling down the code from Git, and want to be on the latest version in development, be sure to checkout whatever *release* branch exists at the time. If you want the official releases, you can stick with the *stable* branch.