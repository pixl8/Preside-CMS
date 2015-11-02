---
id: submittingchanges
title: Submitting fixes, improvements and awesome new features
---

The primary mechanism for submitting changes to the codebase is via [GitHub Pull Requests](https://help.github.com/articles/proposing-changes-to-a-project-with-pull-requests/). The recommended practice for doing this is as follows:

1. Fork and clone the primary [PresideCMS repository](https://github.com/pixl8/Preside-CMS) (see [[buildfromsource]] for further instructions)

2. For each new bug / feature or improvement you wish to make, **create a new branch** forked from the branch named "stable". If you are working against a ticket in [JIRA](https://presidecms.atlassian.net/), include the issue number in the branch name. For example:
```
/preside> git checkout -b PRESIDECMS-266_awesomenewfeature stable
```
3. Make your changes and commit to your local clone and push to your GitHub fork, remember to include the JIRA issue number in your commit messages.

4. When you're ready, visit your branch in GitHub and [make a Pull Request](https://help.github.com/articles/creating-a-pull-request/) from your new branch to the PresideCMS stable branch.

After a pull request has been made, it will be reviewed and we may ask you to make ammendments. At this point, all you need to do is make those changes in your new feature branch and push them back to your fork in GitHub - the changes will automatically make it into the Pull Request.

When we're all happy with the request, we'll manually merge it into the primary repository ready for the upcoming release (see [[branchingmodel]]).