---
id: adminrecordviews-nondatamanager
title: Using admin record views beyond the Data Manager
---

## Overview

As of **Preside 10.9.0**, the admin system comes with a [[adminrecordviews|framework for displaying single records]] through the data manager. This guide shows you how to re-use core viewlets for displaying records outside of datamanager. It covers:

* Registering an admin link builder
* Re-using the entire render record view
* Re-using the render view group view
* Rendering an individual property

## Registering an admin link builder

If your object is **not** managed in Data Manager and has its own view record endpoint in the admin, you should supply a link builder so that related records can link back to your custom object's record.

To do so, add a `@adminBuildViewLinkHandler` attribute to your object to define the _handler_ that will build a link to the given record:

```luceescript
// /application/preside-objects/my_object.cfc

/**
 * @adminBuildViewLinkHandler admin.myObjectManager.buildViewLink
 */
component {
	// ...
}
```

The custom link builder handler will be passed `objectName` and `recordId` arguments so that it can build the link appropriately. For example:

```luceescript
// /application/handlers/admin/MyObjectManager.cfc
component {

	private string function buildViewLink( event, rc, prc, objectName, recordId ) {
		return event.buildAdminLink(
			  linkto      = "myObjectmanager.viewRecord"
			, queryString = "id=" & arguments.recordId 
		);
	}

	// etc.

}
```

>>> If your handler is specific to one object only, you can of course ignore the `objectName` argument as above.

### Re-using the entire render record view

To render a record using the exact same system as Data Manager, you can render the `admin.dataHelpers.viewRecord` viewlet, passing in the required `objectName` and `recordId` args and optionally supplying a `version` arg:

```lucee
<cfoutput>
	#renderViewlet(
		  event = "admin.dataHelpers.viewRecord"
		, args  = { objectName="my_object", recordId=rc.id, version=rc.version }
	)#

	<!--- more custom output for the object here perhaps --->
</cfoutput>
```

### Re-using the render view group view

If you want to just render one of those nifty boxes for a display group (see [[]]), you can use the `admin.dataHelpers.displayGroup` viewlet, again passing in the required `objectName` and `recordId` args and optionally supplying a `version` arg. In addition, you must pass `title`, `iconClass`, and a `properties` arg:

```lucee
<cfoutput>
	#renderViewlet( event="admin.dataHelpers.displayGroup", args={
		  objectName = "my_object"
		, recordId   = rc.id
		, version    = rc.version 
		, title      = "Box title"
		, iconClass  = "fa-some-icon"
		, properties = [ "label", "some_properties", "another_property" ]
	} )#

	<!--- more custom output for the object here perhaps --->
</cfoutput>
```

### Rendering an individual property

To re-use the rendering logic to render a single property, you can use the [[admindataviewsservice-renderfield]] method from the [[api-admindataviewsservice]] service. For example:

```luceescript
// ...
var renderedField = adminDataViewsService.renderField(
	  objectName   = "my_object"
	, propertyName = "my_property"
	, recordId     = rc.id
	, value        = record.my_property
);
// ... etc.
```

### Summary

Use any combination of the above to craft your own record views without having to reinvent too many wheels!