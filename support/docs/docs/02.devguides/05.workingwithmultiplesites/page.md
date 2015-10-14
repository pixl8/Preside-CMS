---
id: workingwithmultiplesites
title: Working with multiple sites
---

## Overview

PresideCMS allows users to create and manage multiple sites. This is perfect for things like microsites, different language sites and any other organisation of workflows and users.

![Screenshot showing the site picker that appears in the administrator for users with access to multiple sites and / or users with access to the site manager.](images/screenshots/site_picker.png)
    

From a development standpoint, the CMS allows developers to create and maintain multiple site templates. A site template is very similar to a Preside Extension, the difference being that the site template is only active when the currently active site is using the template.

Finally, the CMS allows you to easily segment the data in your Preside data objects by site. By doing so, each site will only have access to the data that is unique to it. The developers are in control of which data objects have their data shared across all sites and which objects have their data segmented per site.

## Site templates

Site templates are like a PresideCMS application within another PresideCMS application. They can contain all the same folders and concepts as your main application but are only active when the currently active site is using the template. This means that any widgets, page types, views, etc. that are defined within your site template, will only kick in when the site that uses the template is active. CMS administrators can apply a single template to a site.

![Screenshot of an edit site form where the user can choose which template to apply to the site.](images/screenshots/edit_site.png) 


### Creating a barebones site template

To create a new site template, you will need to create a folder under your application's `application/site-templates/` folder (create one if it doesn't exist already). The name of your folder will become the name of the template, e.g. the following folder structure will define a site template with an id of `microsite`:

```
/application
    /site-templates
        /microsite
```

In order for the site template to appear in a friendly manner in the UI, you should also add an i18n properties file that corresponds to the site id. In the example above, you would create `/application/i18n/site-templates/microsite.properties`:

```properties
title=Microsite template
description=The microsite template provides layouts, widgets and page types that are unique to the site's microsites
```

### Overriding layouts, views, forms, etc.

To override any PresideCMS features that are defined in your main application, you simply need to create the same files in the same directory structure within your site template.

For example, if you wanted to create a different page layout for a site template, you might want to override the main application's `/application/layouts/Main.cfm` file. To do so, simply create `/application/site-templates/mytemplate/layouts/Main.cfm`:

```
/application
    /layouts
        Main.cfm <-- this will be used when the active site is *not* using the 'microsite' site template
    /site-templates
        /microsite
            /layouts
                Main.cfm <-- this will be used when the active site is using the 'microsite' site template
```

This technique can be used for Form layouts, Widgets, Page types and i18n. It can also be used for Coldbox views, layouts and handlers.

>>>> You cannot make modifications to :doc:`presideobjects` with the intention that they will only take affect for sites using the current site template. Any changes to :doc:`presideobjects` affect the database schema and will always take affect for every single site and site template.
>>>> If you wish to have different fields on the same objects but for different site templates, we recommend defining all the fields in your core application's object and providing different form layouts that show / hide the relevent fields for each site template.

### Creating features unique to the site template

To create features that are unique to the site template, simply ensure that they are namespaced suitably so as not to conflict with other extensions and site templates. For example, to create an "RSS Feed" widget that was unique to your site template, you might create the following file structure:

```
/application
    /site-templates
        /microsite
            /forms
                /widgets
                    microsite-rss-widget.xml
            /i18n
                /widgets
                    microsite-rss-widget.properties
            /views
                /widgets
                    microsite-rss-widget.cfm
```

