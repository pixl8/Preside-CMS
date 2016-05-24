---
id: admin-applications
title: Creating multiple admin applications
---

As of v10.6.0, PresideCMS offers the ability to define multiple admin applications. The "CMS" is the single default application and, if you define more than one application, your admin interface will receive a new application switcher:


![Screenshot showing an example application switcher](images/screenshots/application_switcher.jpg)

## Defining applications

Applications are defined in your systems `Config.cfc` file. The setting `settings.adminApplications` is an array containing definitions of applications. Applications can be added simply as an ID string, or a structure with detailed information about the application:

```luceescript
// Config.cfc

// simple configuration, using convention for individual settings
settings.adminApplications.append( "ems" );

// detailed configuration, equivalent to the above:
settings.adminApplications.append( {
      id                 = "ems"
    , feature            = "ems"
    , accessPermission   = "ems.access"
    , defaultEvent       = "admin.ems"
    , activeEventPattern = "^admin\.ems\..*"
    , layout             = "ems"
} );
```

### Features and permissions

To work fully, your admin application's will also need to define features and permissions for the application in Config.cfc. A minimum configuration could look like this:

```luceescript
// Config.cfc

settings.adminApplications.append( {
      id                 = "ems"
    , feature            = "ems"
    , accessPermission   = "ems.access"
    , defaultEvent       = "admin.ems"
    , activeEventPattern = "^admin\.ems.*"
    , layout             = "ems"
} );

settings.features.ems             = { enabled=true, siteTemplates=[ "*" ] };
settings.adminPermissions.ems     = [ "access" ];
settings.adminRoles.eventsManager = [ "ems.*" ];
```

See [[api-featureservice]] and [[cmspermissioning]] for more details on features and permissions.

### Layout

The system expects an alternative Coldbox layout for each application and defaults that layout to the ID of your application. This allows you to override the look and feel, and behaviour of the admin UI. For instance, if your application's "ID" was "ems", create a layout file at `/layouts/ems.cfm`. This layout file would be responsible for the entire HTML layout of the admin pages for this application.

>>>>>> The core "admin" layout might be a good place to start when thinking about building a new layout. It can be found at `/preside/system/layouts/admin.cfm`.

### Default event and 'active event pattern'

Your admin application should have a default landing page event handler. By default, this will be `admin.{appid}`, e.g. `admin.ems`. You can also supply a regex pattern that will be matched against the current coldbox event, to determine whether or not your application is active. The defualt for this is `^admin\.{appid}.*`. For our "ems" example, this means that all Coldbox events beginning with "admin.ems" will lead to the ems application being set as active.


The default handler might be look something like this:

```luceescript
// /handlers/admin/Ems.cfc

// notice that we extend base admin handler
component extends="preside.system.base.AdminHandler" {

// PRE HANDLER
    
    // preHandler useful for doing basic security checks,
    // and any other handler-wide logic
    function preHandler( event, rc, prc ) {
        super.preHandler( argumentCollection = arguments );

        if ( !isFeatureEnabled( "ems" ) ) {
            event.notFound();
        }

        _checkPermissions( argumentCollection=arguments, key="access" );

        prc.pageIcon = "calendar";
    }

// DIRECT PUBLIC ACTIONS
    public void function index() {
        // any required logic for your landing page
    }

// PRIVATE HELPERS
    private void function _checkPermissions( event, rc, prc, required string key ) {
        var permKey   = "ems." & arguments.key;
        var permitted =  hasCmsPermission( permissionKey=permKey );

        if ( !permitted ) {
            event.adminAccessDenied();
        }
    }
}
```

