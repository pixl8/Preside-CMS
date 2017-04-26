---
title: Documentation structure
id: docs-structure
---

All of the source files for this documentation can be found in the `/docs` folder of the public repository; i.e. [https://github.com/pixl8/Preside-CMS/tree/stable/support/docs/docs](https://github.com/pixl8/Preside-CMS/tree/stable/support/docs/docs).

The content is organised by a very simple system of folders and markdown files.

## Folders

Folders containing a single markdown file represent a page of documentation. Subfolders are used to place pages beneath other pages to form a documentation tree. 

Special folder naming rules:

* Folders whose name begin with a number followed by a period are treated as pages that will appear in main navigation - the number indicating the relative order in which the page should appear

* Folders and markdown files whose names begin with an underscore, `_`, are ignored by the tree system and may be used by particular page types to provide more structured content

## Page types

Page types are indicated by the **name** of the markdown file within the page's folder. 

For example, if we are creating a function reference page, you would expect the following folder and file structure:

```
/nameoffunction
    function.md
```

The various build systems can use the page types to format the output in different ways.


## Page IDs

Page IDs are used for cross referencing and are specified in the page's markdown file using YAML front matter. e.g.

```html
---
id: function-abs
title: Abs()
---
```

>>>>>> The name of the folder, without any preceding order number, will be used when an ID is not supplied in the markdown file's YAML front matter.
See [[docs-markdown]] for a full guide to cross referencing and YAML front matter. 