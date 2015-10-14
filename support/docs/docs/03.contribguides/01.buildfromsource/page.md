---
id: buildfromsource
title: Building Preside locally
---

In order to run Preside from a local copy of the codebase, the system requires that external dependencies be pulled in to the expected locations in the project. Before continuing, you will need to make sure you have ant installed. Build steps:

* Clone the [GitHub repository](https://github.com/pixl8/Preside-CMS) (you probably want to fork it first)
* Run the ant buildfile found at rootdir/support/build/build.xml with the `install-preside-deps task`

i.e.

```
/preside/support/build/>ant install-preside-deps
```

