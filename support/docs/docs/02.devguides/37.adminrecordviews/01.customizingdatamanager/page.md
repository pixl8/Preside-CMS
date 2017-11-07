---
id: adminrecordviews-customizedatamanager
title: Customizing record views in Data manager
---

## Overview

As of **Preside 10.9.0**, the admin system comes with a [[adminrecordviews|framework for displaying single records]] through the data manager. This guide shows you how to customize the appearance of the view for individual objects.

### View groups

One of the first features you might want to customize is the grouping of fields in the default view of a record for your object. 

The standard groups are `default` and `system` and these will appear in your view with core Preside fields in the `system` "box" and everything else in the `default` "box". By default, the `default` group's title will be the name of the object, and will have a sort order of `1` while the system group will have a sort order of `2`:

![Screenshot showing example data view with standard groups](images/screenshots/adminviewStandardGroups.jpg)

#### Assign a property to a group

To assign a property to a particular view group, use the `adminViewGroup` attribute on the `property` definition, e.g.

```luceescript
// category.cfc
component {
	property name="label" adminViewGroup="system";
}
```

The above change to our object would lead to a grouping as below:

![Screenshot showing example data view with only a system group](images/screenshots/adminviewOnlySystemGroup.jpg)

#### Creating and customizing groups

A group is automatically registered as soon as it is referenced by the `adminViewGroup` attribute on a property. For instance, if we wanted to add a new `many-to-many` `posts` property on category and assign it to a group named 'posts', we could do so:


```luceescript
// category.cfc
component {
	property name="label" adminViewGroup="system";
	property name="posts" adminViewGroup="posts" relationship="many-to-many" relatedto="blog_post" relatedvia="blog_post_category";
}
```

![Screenshot showing example data view with a custom group](images/screenshots/adminviewCustomGroup.jpg)

We can then use convention to give the group a translatable name, icon and sort order. Add the following keys to the corresponding `.properties` file for you object:

```properties
viewgroup.{groupname}.title=A group title
viewgroup.{groupname}.iconClass=fa-icon
viewgroup.{groupname}.sortorder=2
```

For example, in our `category.properties` file:

```properties
# /application/i18n/preside-objects/category.properties

# ...

viewgroup.posts.title=Posts
viewgroup.posts.iconClass=fa-file-text-o
viewgroup.posts.sortorder=1

viewgroup.system.title=Category
viewgroup.system.iconClass=fa-tag
viewgroup.system.sortorder=2
```

Leads to:

![Screenshot showing example data view with a custom group decorated with custom labelling](images/screenshots/adminviewCustomGroupWithLabels.jpg)





### Field renderers

### Field sort orders

### Richeditor preview layout