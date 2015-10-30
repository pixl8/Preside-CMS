---
id: submittingchanges
title: Submitting fixes, improvements and awesome new features
---

The primary mechanism for submitting changes to the codebase is via [GitHub Pull Requests](). The recommended practice for doing this is as follows:

1. Fork and clone the primary [PresideCMS repository](https://github.com/pixl8/Preside-CMS) (see [[buildfromsource]] for further instructions)

2. For each new bug / feature or improvement you wish to make, **create a new branch** forked from the branch named "stable". If you are working against a ticket in [JIRA](https://presidecms.atlassian.net/), include the issue number in the branch name. For example:
```
/preside> git checkout -b PRESIDECMS-266_awesomenewfeature stable
```
3. Make your changes and commit to your local clone and push to your GitHub fork, remember to include the JIRA issue number in your commit messages.

4. When you're ready, visit your branch in GitHub and make a [Pull Request]() from your new branch to the PresideCMS stable branch. (screenshots needed).