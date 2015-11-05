---
id: adminlefthandmenu
title: Modifying the administrator left hand menu
---

## Overview

PresideCMS provides a simple mechanism for configuring the left hand menu of the administrator, either to add new main navigational sections, take existing ones away or to modify the order of menu items.

## Configuration

Each top level item of the menu is stored in an array that is set in `settings.adminSideBarItems` in `Config.cfc`. The core implementation looks like this:

```luceescript
component {

    public void function configure() {
        
        // ... other settings ...

        settings.adminSideBarItems = [
              "sitetree"
            , "assetmanager"
            , "datamanager"
            , "usermanager"
            , "websiteUserManager"
            , "systemConfiguration"
            , "updateManager"
        ];

        // ... other settings ...

    }
}
```

Each of these side bar items is then implemented as a view that lives under a `/views/admin/layout/sidebar/` folder. For example, for the 'sitetree' item, there exists a view at `/views/admin/layout/sidebar/sitetree.cfm` that looks like this:

```luceescript
// /views/admin/layout/sidebar/sitetree.cfm

if ( hasCmsPermission( "sitetree.navigate" ) ) {
    Echo( renderView(
          view = "/admin/layout/sidebar/_menuItem"
        , args = {
              active  = ListLast( event.getCurrentHandler(), ".") eq "sitetree"
            , link    = event.buildAdminLink( linkTo="sitetree" )
            , gotoKey = "s"
            , icon    = "fa-sitemap"
            , title   = translateResource( 'cms:sitetree' )
          }
    ) );
}
```

## Core view helpers

There are two core views that can be used when rendering your menu items, `/admin/layout/sidebar/_menuItem` and `/admin/layout/sidebar/_subMenuItem`.

### /admin/layout/sidebar/_menuItem

Renders a top level menu item.

#### Arguments

<div class="table-responsive">
	<table class="table">
		<thead>
			<tr>
				<th>Argument</th>
				<th>Description</th>
			</tr>
		</thead>
		<tbody>
			<tr><td>active</td>        <td>Boolean. Whether or not the current page lives within this part of the CMS.</td></tr>
			<tr><td>link</td>          <td>Where this menu item points to. Not needed when the menu item has a submenu.</td></tr>
			<tr><td>title</td>         <td>Title of the menu item</td></tr>
			<tr><td>icon</td>          <td>Icon class for the menu item. We use font awesome, so "fa-users" for example.</td></tr>
			<tr><td>subMenu</td>       <td>Rendered submenu items.</td></tr>
			<tr><td>subMenuItems</td>  <td>Array of sub menu items to render (alternative to supplying a rendered sub menu). Each item should be a struct with `link`, `title` and optional `gotoKey` keys</td></tr>
			<tr><td>gotoKey</td>       <td>Optional key that when used in combination with the `g` key, will send the user to the item's link. e.g. `g+s` takes you to the site tree.</td></tr>
		</tbody>
	</table>
</div>

#### Example

```lucee
<cfscript>
    subMenuItems = [];

    if ( hasCmsPermission( "mynewsubfeature.access" ) ) {
        subMenuItems.append( {
            link  = event.buildAdminLink( linkTo="mynewsubfeature" ) 
            , title = translateResource( uri="mynewsubfeature:menu.title" )
        } );
    }

    if ( hasCmsPermission( "myothernewsubfeature.access" ) ) {
        subMenuItems.append( {
              link  = event.buildAdminLink( linkTo="myothernewsubfeature" ) 
            , title = translateResource( uri="myothernewsubfeature:menu.title" )
        } );
    }
</cfscript>

#renderView( view="/admin/layout/sidebar/_menuItem", args={
      active       = ReFindNoCase( "my(other)?newsubfeature$", event.getCurrentHandler() )
    , title        = translateResource( uri="mynewfeature:menu.title" )
    , icon         = "fa-world-domination"
    , subMenuItems = subMenuItems
} )#
```

### /admin/layout/sidebar/_subMenuItem

Renders a sub menu item.

#### Arguments

<div class="table-responsive">
	<table class="table">
		<thead>
			<tr>
				<th>Argument</th>
				<th>Description</th>
			</tr>
		</thead>
		<tbody>
			<tr><td>link</td>    <td>Where this menu item points to.</td></tr>
			<tr><td>title</td>   <td>Title of the menu item</td></tr>
			<tr><td>gotoKey</td> <td>Optional key that when used in combination with the `g` key, will send the user to the item's link. e.g. `g+s` takes you to the site tree.</td></tr>
		</tbody>
	</table>
</div>

#### Example

```lucee
<cfif hasCmsPermission( "mynewsubfeature.access" )>
    #renderView( view="/admin/layout/sidebar/_subMenuItem", args={
          link    = event.buildAdminLink( linkTo="mynewsubfeature" )
        , title   = translateResource( uri="mynewsubfeature:menu.title" )
        , gotoKey = "f"
    } )#
</cfif>
```

## Examples

### Adding a new item

Firstly, add the item to our array of sidebar items in your site or extension's Config.cfc:

```luceescript
// ...

settings.adminSideBarItems.append( "mynewfeature" );

// ...
```

Finally, create the view for the side bar item:

```lucee
<!-- /views/admin/layout/sidebar/mynewfeature.cfm -->
<cfif hasCmsPermission( "mynewfeature.access" )>
    <cfoutput>
        #renderView( view="/admin/layout/sidebar/_menuItem", args={
              active       = ReFindNoCase( "mynewfeature$", event.getCurrentHandler() )
            , title        = translateResource( uri="mynewfeature:menu.title" )
            , link         = event.buildAdminLink( linkTo="mynewfeature" )
            , icon         = "fa-world-domination"
            , subMenuItems = subMenuItems
        } )#
    </cfoutput>
</cfif>
```

>>> In order for the calls to `hasCmsPermission()` and `translateResource()` to do anything useful, you will need to have setup the necessary permission keys (see [[permissioning]]) and resource bundle keys (see [[i18n]]).

### Remove an existing item

In your site or extension's `Config.cfc` file:

```luceescript
// ...

// delete the site tree menu item, for example:
settings.adminSideBarItems.delete( "sitetree" );

// ...
```