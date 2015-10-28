---
id: buildfromsource
title: Building Preside locally
---

In order to run Preside from a local copy of the codebase, the system requires that external dependencies be pulled in to the expected locations in the project. Before continuing, you will need to make sure you have [CommandBox](https://www.ortussolutions.com/products/commandbox) installed and available in your path. Build steps:

1. [Fork](https://help.github.com/articles/fork-a-repo/) the [GitHub repository](https://github.com/pixl8/Preside-CMS)
2. [Make a local clone](https://help.github.com/articles/cloning-a-repository/) of your forked repository
3. Run the `box install` to have CommandBox pull in all of presides dependancies that are declared in its `box.json` file:
```
/preside> box install
```

Once you have the repository cloned to your local machine, you can create a `/preside` mapping in your Preside applications that points at your clone in order to be able to develop on and test against the codebase.

