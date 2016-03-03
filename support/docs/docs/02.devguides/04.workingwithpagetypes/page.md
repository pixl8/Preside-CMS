---
id: workingwithpagetypes
title: Working with page types
---

## Overview

Page types allow developers to wire *structured content* to website pages that are stored in the *site tree*. They are implemented in a way that is intuitive to the end-users and painless for developers.

### Architecture

#### Pages

Pages in a site's tree are stored in the `page` preside object. This object stores information that is common to all pages such as *title* and *slug*.

#### Page types

All pages in the tree must be associated with a page *type*; this page type will define further fields that are specific to its purpose. Each page type will have its own Preside Object in which the specific data is stored. For example, you might have an "event" page type that had *Start date*, *End date* and *Location* fields.

**A one-to-one relationship exists between each page type object and the page obejct**. This means that every **page type** record must and will have a corresponding **page** record.

## Creating a page type

There are four essential parts to building a page type. The data model, view layer, i18n properties file and form layout(s). 

>>>>>> You can scaffold all the parts of a page template very quickly using the Developer console (see :doc:`developerconsole`). Once in the console, type `new pagetype` and follow the prompts.

### The data model

A page type is defined by creating a **Preside Data Object** (see [[presidedataobjects]]) that lives in a subdirectory called "page-types". For example: `/preside-objects/page-types/event.cfc`:

```luceescript
// /preside-objects/page-types/event.cfc
component {
    property name="start_date" type="date"   dbtype="date"                  required=true;
    property name="end_date"   type="date"   dbtype="date"                  required=true;
    property name="location"   type="string" dbtype="varchar" maxLength=100 required=false; 
}
```

Under the hood, the system will add some fields for you to cement the relationship with the 'page' object. The result would look like this:

```luceescript
// /preside-objects/page-types/event.cfc
component labelfield="page.title" {
    property name="start_date" type="date"   dbtype="date"                  required=true;
    property name="end_date"   type="date"   dbtype="date"                  required=true;
    property name="location"   type="string" dbtype="varchar" maxLength=100 required=false; 

    // auto generated property (you don't need to create this yourself)
    property mame="page" relationship="many-to-one" relatedto="page" required=true uniqueindexes="page" ondelete="cascade" onupdate="cascade";
}
```

>>> Notice the "page.title" **labelfield** attribute on the component tag. This has the effect of the 'title' field of the related 'page' object being used as the labelfield (see :ref:`presideobjectslabelfield`).
>>> **You do not need to specify this yourself, written here as an illustration of what gets added under the hood.**

### View layer

The page types system takes advantage of auto wired views (see [[presidedataobjectviews]]). What this means is that we do not need to create a service layer or a coldbox handler for our page type, PresideCMS will take care of wiring your view to your page type data object.

Using our "event" page type example, we would create a view file at `/views/page-types/event/index.cfm`. A simplified example might then look something like this:

```lucee
<!-- /views/page-types/event/index.cfm -->
<cfparam name="args.title"      field="page.title"       editable="true" />
<cfparam name="args.start_date" field="event.start_date" editable="true" />
<cfparam name="args.end_date"   field="event.end_date"   editable="true" />
<cfparam name="args.location"   field="event.location"   editable="true" />

<cfoutput>
    <h1>#page.title#</h1>
    <div class="dates-and-location">
        <p>From #args.start_date# to #args.end_date# @ #args.location#</p>
    </div>
</cfoutput>
```

#### Using a handler

If you need to do some handler logic before rendering your page type, you take full control of fetching the data and rendering the view for your page type. 

You will need to create a handler under a 'page-types' folder who's filename matches your page type object, e.g. `/handlers/page-types/event.cfc`. The "index" action will be called by default and will be called as a Preside Viewlet (see [[presideviewlets]]). For example:

```luceescript
component {

    private string function index( event, rc, prc, args ) {
        args.someValue = getModel( "someServiceOrSomesuch" ).getSomeValue();

        return renderView( 
              view          = "/page-types/event/index"
            , presideObject = "event"
            , id            = event.getCurrentPageId()
            , args          = args 
        );
    }
}
```

#### Multiple layouts

You can create layout variations for your page type that the users of the CMS will be able to select when creating and editing the page. To do this, simply create multiple views in your page type's view directory. For example:

```
/views
    /page-types
        /event
            _ignoredView.cfm
            index.cfm
            special.cfm
```

>>> Any views that begin with an underscore are ignored. Use these for reusable view snippets that are not templates in themselves.

If your page type has more than one layout, a drop down will appear in the page form, allowing the user to select which template to use. 

![Screenshot of a layout picker.](images/screenshots/layout_picker.png)

You can control the labels of your layouts that appear in the dropdown menu by adding keys to your page type's i18n properties file (see UI and i18n below).


### UI and i18n

In order for the page type to appear in a satisfactory way for your users when creating new pages (see screenshot below), you will also need to create a `.properties` file for the page type. 


For example, if your page type **Preside data object** was, `/preside-objects/page-types/event.cfc`, you would need to create a `.properties` file at, `/i18n/page-types/event.properties`. In it, you will need to add *name*, *description* and *iconclass* keys, e.g.

```properties
# mandatory keys
name=Event
description=An event page
iconclass=fa-calendar

# keys for the add / edit page forms (completely up to you, see below)
tab.title=Event fields
field.title.label=Event name
field.start_date.label=Start date
field.end_date.label=End date
field.location.label=Location

# keys for the layout picker
layout.index=Default
layout.special=Special layout
```

### Add and edit page forms

The core PresideCMS system ships with default form layouts for adding and editing pages in the site tree. The page types system allows you to modify those forms for specific page types.

![Screenshot of a typical edit page form.](images/screenshots/edit_page.png)

To achieve this, you can either create a single form layout that will be used to modify both the **add** and **edit** forms, or a layout for each form. For example, the following form layout will modify the layout forms for our "event" page type example:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!--
    To use this layout for both edit and add modes, the file would be:

        /application/forms/page-types/event.xml

    For individual add / edit forms:

        /application/forms/page-types/event.add.xml
        /application/forms/page-types/event.edit.xml
-->
<form>
    <tab id="main">
        <fieldset id="main">
            <!-- modify the label for the 'title' field to be event specific (uses a key from our i18n properties file above) -->
            <field name="title" label="page-types.event:field.title.label" />

            <!-- delete some fields that we don't want to see for event pages -->
            <field name="parent_page" deleted="true" />
            <field name="active"      deleted="true" />
            <field name="slug"        deleted="true" />
            <field name="layout"      deleted="true" />
        </fieldset>
    </tab>

    <!-- add some new fields in a new tab -->
    <tab id="event-fields" title="page-types.event:tab.title">
        <fieldset id="event-fields">
            <field binding="event.start_date" label="page-types.event:field.start_date.label" />
            <field binding="event.end_date"   label="page-types.event:field.end_date.label" />
            <field binding="event.location"   label="page-types.event:field.location.label" />
        </fieldset>
    </tab>
</form>
```

### Controlling behaviour in the tree

There are a number of flags that you can set in your page type object files to determine how the pages can be used and viewed within the tree. 

#### Limiting child and parent page types

A common scenario is to limit child page and parent types to related pages, for example, **blog** and **blog post** pages. You can control this behaviour by adding `@allowedParentPageTypes` and `@allowChildPageTypes` annotations to your page type objects.

For example, to create an exclusive relationship bewteen parent and child types, you would add the following metadata to your object files:

```luceescript

// /preside-objects/page-types/blog.cfc
/**
 * @allowedParentPageTypes *
 * @allowedChildPageTypes  blog_post
 *
 */
component {
  // ...   
}

// /preside-objects/page-types/blog.cfc
/**
 * @allowedParentPageTypes blog
 * @allowedChildPageTypes  none
 *
 */
component {
  // ...   
}
```

#### Externalizing management of pages (hiding from the tree)

Another common scenario is to want to manage certain page types _outside_ of the site tree. For example, if you have 10,000 article pages, managing them in the tree UI is particularly impractical. This can be achieved using the `showInSiteTree` and `sitetreeGridFields` annotations in your page type objects.

Again, using a blog post page type as an example:

```luceescript
// /preside-objects/page-types/blog_post.cfc

/**
 * @allowedParentPageTypes blog
 * @allowedChildPageTypes  none
 * @showInSiteTree         false
 * @sitetreeGridFields     page.title,blog_post.post_date,page.active
 *
 */
component {
  // ...   
}
```

This results in the "Manage blog post pages..." UI in the tree as seen below:

![Screenshot of a managed pages link](images/screenshots/sitetree_managedpages.jpg)

And a grid view of the blog pages that appears as below:

![Screenshot of a managed pages grid](images/screenshots/sitetree_managedpagesgrid.jpg)

