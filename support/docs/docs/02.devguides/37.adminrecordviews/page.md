---
id: adminrecordviews
title: Admin record views
---

## Overview

As of **Preside 10.9.0**, the admin system comes with a framework for displaying single records through the data manager. An example might look like this:

![Screenshot showing example data view](images/screenshots/presidedataview.jpg)

This view is automatically available to any object that is managed in the data manager and will display fields and relationships of a record, grouped into configurable display boxes. The display groups, sort order and renderers for fields are all fully customizable. You are even able to use your own handler entirely for displaying a record.

In addition, as a developer, you are able to re-use core admin [[presideviewlets|viewlets]] to quickly build your own view record screens for custom admin areas. See the guides below for detailed documentation:

* [[adminrecordviews-customizedatamanager]]
* [[adminrecordviews-nondatamanager]]