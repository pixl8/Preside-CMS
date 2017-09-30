---
id: cmspermissioning
title: CMS permissioning
---

## Overview

CMS Permissioning is split into three distinct concepts in PresideCMS:

### Permissions and roles

These are defined in configuration and are not editable through the CMS GUI.

* **Permissions** allow you to grant or deny access to a particular action
* **Roles** provide convenient grant access to one or more permissions

### Users and groups

Users and groups are defined through the administrative GUI and are stored in the database.

* An *active* **user** must belong to one or more groups
* A **group** must have one or more *roles*

Permissions are granted to a user through the roles that are associated with the groups that she belongs to.

### Contextual permissions

Contextual permissions are fine grained permissions implemented specifically for any given area of the CMS that requires them.

For example, you could deny the "*Freelancers*" user group the "*Add pages*" permission for a particular page and its children in the sitetree; in this case, the context is the ID of the page.

Contextual permissions are granted or denied to user **groups** and always take precedence over permissions granted through groups and roles.

>>> If a feature of the CMS requires context permissions, it must supply its own views and handlers for managing them. PresideCMS helps you out here with a viewlet and action handler for some common UI and saving logic, see 'Rolling out Context Permission GUIs', below.

## Configuring permissions and roles

Permissions and roles are configured in your site or extension's `Config.cfc` file. An example configuration might look like this:

```luceescript

public void function configure() {
    super.configure();

// PERMISSIONS
    // here we define a feature, "analytics dashboard" with a number of permissions
    settings.adminPermissions.analyticsdashboard = [ "navigate", "share", "configure" ];

    // features can be organised into sub-features to any depth, here
    // we have a depth of two, i.e. "eventmanagement.events"
    settings.adminPermissions.eventmanagement = {
          events = [ "navigate", "view", "add", "edit", "delete" ]
        , prices = [ "navigate", "view", "add", "edit", "delete" ]
    };

    // The settings above will translate to the following permission keys being
    // available for use in your Railo code, i.e. if ( hasCmsPermission( userId, permissionKey ) ) {...}:
    //
    // analyticsdashboard.navigate
    // analyticsdashboard.share
    // analyticsdashboard.configure
    //
    // eventmanagement.events.navigate
    // eventmanagement.events.view
    // eventmanagement.events.add
    // eventmanagement.events.edit
    // eventmanagement.events.delete
    //
    // eventmanagement.prices.navigate
    // eventmanagement.prices.view
    // eventmanagement.prices.add
    // eventmanagement.prices.edit
    // eventmanagement.prices.delete

// ROLES
    // roles are simply a named array of permission keys
    // permission keys for roles can be defined with wildcards (*)
    // and can be excluded with the ! character:

    // define a new role, with all event management perms except for delete
    settings.adminRoles.eventsOrganiser = [ "eventmanagement.*", "!*.delete" ];

    // another new role specifically for analytics viewing
    settings.roles.analyticsViewer = [ "analyticsdashboard.navigate", "analyticsdashboard.share" ];

    // add some new permissions to some existing core roles
    settings.adminRoles.administrator = settings.roles.administrator ?: [];
    settings.adminRoles.administrator.append( "eventmanagement.*" );
    settings.adminRoles.administrator.append( "analyticsdashboard.*" );

    settings.adminRoles.someRole = settings.roles.someRole ?: [];
```

### Defining names and descriptions (i18n)

Names and descriptions for your roles and permissions must be defined in i18n resource bundles.

For roles, you should add *name* and *description* keys for each role to the `/i18n/roles.properties` file, e.g.

```properties
eventsOrganiser.title=Events organiser
eventsOrganiser.description=The event organiser role grants aspects to all aspects of event management in the CMS except for deleting records (which must be done by the administrator)

analyticsViewer.title=Analytics viewer
analyticsViewer.description=The analytics viewer role grants permission to view statistics in the analytics dashboard
```

For permissions, add your keys to the `/i18n/permissions.properties` file, e.g.


```properties
eventmanagement.events.navigate.title=Events management navigation
eventmanagement.events.navigate.description=View events management navigation links

eventmanagement.events.view=title=View events
eventmanagement.events.view=description=View details of events that have been entered into the system
```

>>> For permissions, you may only want to create resource bundle entries when the permissions will be used in contextual permission GUIs. Otherwise, the translations will never be used.

## Applying permissions in code with hasCmsPermission()

When you wish to permission control a given system feature, you should use the `hasCmsPermission()` method. For example:

```luceescript
// a general permission check
if ( !hasCmsPermission( permissionKey="eventmanagement.events.navigate" ) ) {
    event.adminAccessDenied(); // this is a preside request context helper
}

// a contextual permission check. In this case:
// "do we have permission to add folders to the asset folder with id [idOfCurrentFolder]"
if ( !hasCmsPermission( permissionKey="assetManager.folders.add", context="assetmanagerfolders", contextKeys=[ idOfCurrentFolder ] ) ) {
    event.adminAccessDenied(); // this is a preside request context helper
}
```

>>> The `hasCmsPermission()` method has been implemented as a ColdBox helper method and is available to all your handlers and views. If you wish to access the method from your services, you can access it via the `permissionService` service object, the core implementation of which can be found at `/preside/system/api/security/PermissionService.cfc`.

## Rolling out Context Permission GUIs

Should a feature you are developing for the admin require contextual permissions management, you can make use of a viewlet helper to give you a visual form and handler code to manage them.

For example, if we want to be able to manage permissions on event management *per* event, we might have a view at `/views/admin/events/managePermissions.cfm`, that contained the following code:

```lucee
#renderViewlet( event="admin.permissions.contextPermsForm", args={
      permissionKeys = [ "eventmanagement.events.*", "!*.managePerms" ] <!--- permissions that you want to manage within the form --->
    , context        = "eventmanager"
    , contextKey     = eventId
    , saveAction     = event.buildAdminLink( linkTo="events.saveEventPermissionsAction", querystring="id=#eventId#" )
    , cancelAction   = event.buildAdminLink( linkTo="events.viewEvent", querystring="id=#eventId#" )
} )#
```

Our `admin.events.saveEventPermissionsAction` handler action might then look like this:

```luceescript
function saveEventPermissionsAction( event, rc, prc ) {
    var eventId = rc.id ?: "";

    // check that we are allowed to manage the permissions of this event, or events in general ;)
    if ( !hasCmsPermission( permissionKey="eventmanager.events.manageContextPerms", context="eventmanager", contextKeys=[ eventId ] ) ) {
      event.adminAccessDenied();
    }

    // run the core 'admin.Permissions.saveContextPermsAction' event
    // this will save the permissioning configured in the
    // 'admin.permissions.contextPermsForm' form
    var success = runEvent( event="admin.Permissions.saveContextPermsAction", private=true );

    // redirect the user and present them with appropriate message
    if ( success ) {
      messageBox.info( translateResource( uri="cms:eventmanager.permsSaved.confirmation" ) );
      setNextEvent( url=event.buildAdminLink( linkTo="eventmanager.viewEvent", queryString="id=#eventId#" ) );
    }

    messageBox.error( translateResource( uri="cms:eventmanager.permsSaved.error" ) );
    setNextEvent( url=event.buildAdminLink( linkTo="events.managePermissions", queryString="id=#eventId#" ) );
}
```

## System users

Users that are defined as **system users** are excempt from all permission checking. In effect, they are granted access to **everything**. This concept exists to enable web agencies to manage every aspect of a site while setting up more secure access for their clients.

System users are only configurable through your site's `Config.cfc` file as a comma separated list of login ids. The default value of this setting is 'sysadmin'. For example, in your site's Config.cfc, you might have:

```luceescript
 public void function configure() {
    super.configure();

    // ...

    settings.system_users = "sysadmin,developer"; // both the 'developer' and 'sysadmin' users are now defined as system users
  }
```