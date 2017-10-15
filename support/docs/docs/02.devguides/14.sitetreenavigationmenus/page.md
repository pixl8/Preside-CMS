---
id: sitetreenavigationmenus
title: Sitetree navigation menus
---

## Overview

A common task for CMS driven websites is to build navigation menus based on the site tree. PresideCMS provides two extendable viewlets (see [[viewlets]]) to aid in rendering such menus with the minimum of fuss; `core.navigation.mainNavigation` and `core.navigation.subNavigation`.

## Main navigation

The purpose of the main navigation viewlet is to render the menu that normally appears at the top of a website and that is usually either one, two or three levels deep. For example:

```lucee
<nav role="navigation">
    <ul class="nav navbar-nav">
        <li class="hiddex-sm home-nav"><a href="/"><span class="fa fa-home"></span></a></li>

        #renderViewlet( event="core.navigation.mainNavigation", args={ depth=2 } )#
    </ul>
</nav>
```

This would result in output that looked something like this:

```html
<nav class="site-navigation" role="navigation">
    <ul class="nav navbar-nav">
        <li class="hiddex-sm home-nav"><a href="/"><span class="fa fa-home"></span></a></li>

        <!-- start of "core.navigation.mainNavigation" -->
        <li class="active">
            <a href="/news.html">News</a>
        </li>
        <li class="dropdown">
            <a href="/about.html">About us</a>
            <ul class="dropdown-menu" role="menu">
                <li><a href="/about/team.html">Our team</a></li>
                <li><a href="/about/offices.html">Our offices</a></li>
                <li><a href="/about/ethos.html">Our ethos</a></li>
            </ul>
        </li>
        <li>
            <a href="/contact.html">Contact</a>
        </li>
        <!-- end of "core.navigation.mainNavigation" -->
    </ul>
</nav>
```

>>> Notice how the core implementation does not render the outer `<ul>` element for you. This allows you to build navigation items either side of the automatically generated navigation such as login links and other application driven navigation.

### Viewlet options

You can pass the following arguments to the viewlet through the `args` structure:

<div class="table-responsive">
    <table class="table">
        <thead>
            <tr>
                <th>Name</th>
                <th>Description</th>
            </tr>
        </thead>
        <tbody>
            <tr><td>`rootPage`</td> <td>ID of the page whose children make up the top level of the menu. This defaults to the site's homepage.</td></tr>
            <tr><td>`depth`</td>    <td>Number of nested dropdown levels to drill into. Default is 1, i.e. just render the immediate children of the root page and have no drop downs</td></tr>

            <tr>
                <td>`ulNestedClass`</td>
                <td>You can change the sub menu UL class using this variable. Default:'dropdown-menu'</td>
            </tr>

            <tr>
                <td>`liCurrentClass`</td>
                <td>You can change the class of the current active li using this variable. Default:'active'</td>
            </tr>

            <tr>
                <td>`liHasChildrenClass`</td>
                <td>You can change the sub menu li class using this variable. Default:'dropdown'</td>
            </tr>

            <tr>
                <td>`liHasChildrenAttributes`</td>
                <td>You can configure the addtional attributes for the li using this variable. Default:none</td>
            </tr>

             <tr>
                <td>`aCurrentClass`</td>
                <td>You can change the class of the current active link using this variable. Default:'active'</td>
            </tr>

            <tr>
                <td>`aHasChildrenClass`</td>
                <td>You can change the sub menu achor link class using this variable. Default:none</td>
            </tr>

            <tr>
                <td>`aHasChildrenAttributes`</td>
                <td>You can configure the additional attributes for sub menu achor link using this variable. Default:none</td>
            </tr>
        </tbody>
    </table>
</div>

### Overriding the view

You might find yourself in a position where the HTML markup provided by the core implementation does not suit your needs. You can override this markup by providing a view at `/views/core/navigaton/mainNavigation.cfm`. The view will be passed a single argument, `args.menuItems`, which is an array of structs whose structure looks like this:

```luceescript
[
    {
        "id"       : "F9923DE1-9B2D-4544-A4E7F8E198888211",
        "title"    : "News",
        "active"   : true,
        "children" : []
    },
    {
        "id"       : "F9923DE1-9B2D-4544-A4E7F8E198888A6F",
        "title"    : "About us",
        "active"   : false,
        "children" : [
            {
                "id"       : "F9923DE1-9B2D-4544-A4E7F8E198888000",
                "title"    : "Our team",
                "active"   : false,
                "children" : []
            },
            {
                "id"       : "F9923DE1-9B2D-4544-A4E7F8E198888FF8",
                "title"    : "Our offices",
                "active"   : false,
                "children" : []
            },
            {
                "id"       : "F9923DE1-9B2D-4544-A4E7F8E1988887FE",
                "title"    : "Our ethos",
                "active"   : false,
                "children" : []
            }
        ]
    },
    {
        "id"       : "F9923DE1-9B2D-4544-A4E7F8E19888834A",
        "title"    : "COntact us",
        "active"   : false,
        "children" : []
    }
]
```

This is what the core view implementation looks like:

```lucee
<cfoutput>
    <cfloop array="#( args.menuItems ?: [] )#" index="i" item="item">
        <li class="<cfif item.active>active </cfif><cfif item.children.len()>dropdown</cfif>">
            <a href="#event.buildLink( page=item.id )#">#item.title#</a>
            <cfif item.children.len()>
                <ul class="dropdown-menu" role="menu">
                    <!-- NOTE the recursion here -->
                    #renderView( view='/core/navigation/mainNavigation', args={ menuItems=item.children } )#
                </ul>
            </cfif>
        </li>
    </cfloop>
</cfoutput>
```

## Sub navigation

The sub navigation viewlet renders a navigation menu that is often placed in a sidebar and that shows siblings, parents and siblings of parents of the current page. For example:

```
News
*Events and training*
    Annual Conference
    *Online*
        Free webinars
        *Bespoke online training* <-- current page
About us
Contact us
```

This viewlet works in exactly the same way to the main navigation viewlet, however, the HTML output and the input arguments are very slightly different:

### Viewlet options

<div class="table-responsive">
    <table class="table">
        <thead>
            <tr>
                <th>Name</th>
                <th>Description</th>
            </tr>
        </thead>
        <tbody>
            <tr><td>`startLevel`</td> <td>At what depth in the tree to start at. Default is 2. This will produce a different root page for the menu depending on where in the tree the current page lives</td></tr>
            <tr><td>`depth`</td>      <td>Number of nested menu levels to drill into. Default is 3.</td></tr>
        </tbody>
    </table>
</div>

### Overriding the view

Override the markup for the sub navigation viewlet by providing a view file at `/views/core/navigaton/subNavigation.cfm`. The view will be passed two arguments, `args.menuItems` and `args.rootTitle`. The `args.menuItems` argument is the nested array of menu items. The `args.rootTitle` argument is the title of the root page of the menu (whose children makeup the top level of the menu).

The core view looks like this:

```lucee
<cfoutput>
    <cfloop array="#( args.menuItems ?: [] )#" item="item">
        <li class="<cfif item.active>active </cfif><cfif item.children.len()>has-submenu</cfif>">
            <a href="#event.buildLink( page=item.id )#">#item.title#</a>
            <cfif item.children.len()>
                <ul class="submenu">
                    #renderView( view="/core/navigation/subNavigation", args={ menuItems=item.children } )#
                </ul>
            </cfif>
        </li>
    </cfloop>
</cfoutput>
```

## Crumbtrail

The crumbtrail is the simplest of all the viewlets and is implemented as two methods in the request context and as a viewlet with just a view (feel free to add your own handler if you need one).

The view looks like this:

```lucee
<!-- /preside/system/views/core/navigation/breadCrumbs.cfm -->
<cfset crumbs = event.getBreadCrumbs() />
<cfoutput>
    <cfloop array="#crumbs#" index="i" item="crumb">
        <cfset last = i eq crumbs.len() />

        <li class="<cfif last>active</cfif>">
            <cfif last>
                #crumb.title#
            <cfelse>
                <a href="#crumb.link#">#crumb.title#</a>
            </cfif>
        </li>
    </cfloop>
</cfoutput>
```

>>> Note that again we are only outputting the `<li>` tags in the core view, leaving you free to implement your own list wrapper HTML.

### Request context helper methods

There are two helper methods available to you in the request context, `event.getBreadCrumbs()` and `event.addBreadCrumb( title, link, menuTitle )`.

The `getBreadCrumbs()` method returns an array of the breadcrumbs that have been registered for the request. Each breadcrumb is a structure containing `title`, `link` and `menuTitle` keys.

The `addBreadCrumb()` method allows you to append a breadcrumb item to the current stack. It requires you to pass both a title and a link for the breadcrumb item. The menuTitle is optional, and if omitted or empty will default to the title.

>>> The core site tree page handler will automatically register the breadcrumbs for the current page.
