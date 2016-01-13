---
id: buildfromsource
title: Building Preside locally
---

In order to run Preside from a local copy of the codebase, the system requires that external dependencies be pulled in to the expected locations in the project. Before continuing, you will need to make sure you have [CommandBox](https://www.ortussolutions.com/products/commandbox) installed and available in your path. Build steps:

1. [Fork](https://help.github.com/articles/fork-a-repo/) the [GitHub repository](https://github.com/pixl8/Preside-CMS)
2. [Make a local clone](https://help.github.com/articles/cloning-a-repository/) of your forked repository
3. Run the `box install` command to have CommandBox pull in all of presides dependencies that are declared in its `box.json` file:
```
/preside> box install
```

Once you have the repository cloned to your local machine and have pulled down the dependencies, create a `/preside` mapping in your application that points at your clone. You will then be able to develop in your fork and test the changes in your application. See [[submittingchanges]] for details on how best to contribute your changes back to the project.

## Keeping your fork up to date

When you fork our repository in GitHub, you essentially have a "cut off" repository that is all your own. GitHub have an excellent guide on [working with forks](https://help.github.com/articles/working-with-forks/) that includes information on syncing with an upstream repository, but here is our super quick guide:

```
# add the master repo as a git remote called 'upstream'
git remote add upstream https://github.com/pixl8/Preside-CMS.git

# fetch the latest code from the upstream remote
git fetch upstream

# merge the upstream changes into your local branches
git checkout stable
git merge upstream/stable

# do this for as many branches that you want to
# work with locally
git checkout release-10.2.4
git merge upstream/release-10.2.4

```

For a guide to the git branching model we use, see [[branchingmodel]].
