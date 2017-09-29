---
id: customerrorpages
title: Custom error pages & maintenance mode
---

## Overview

PresideCMS provides a simple mechanism for creating custom `401`, `404` and `500` error pages while providing the flexibility to allow you to implement more complex systems should you need it.


## 404 Not found pages

### Creating a 404 template

The 404 template is implemented as a Preside Viewlet (see [[[viewlets]]) and a core implementation already exists. The name of the viewlet is configured in your application's Config.cfc with the `notFoundViewlet` setting. The default is "errors.notFound":

```luceescript
// /application/config/Config.cfc
component extends="preside.system.config.Config" {

    public void function configure() {
        super.configure();

        // other settings...
        settings.notFoundViewlet = "errors.notFound";
    }
}
```

For simple cases, you will only need to override the `/errors/notFound` view by creating one in your application's view folder, e.g.

```lucee
<!-- /application/views/errors/notFound.cfm -->
<h1>These are not the droids you are looking for</h1>
<p> Some pithy remark.</p>
```

#### Implementing handler logic

If you wish to perform some handler logic for your 404 template, you can simply create the Errors.cfc handler file and implement the "notFound" action. For example:

```luceescript
// /application/handlers/Errors.cfc
component {

    private string function notFound( event, rc, prc, args={} ) {
        event.setHTTPHeader( statusCode="404" );
        event.setHTTPHeader( name="X-Robots-Tag", value="noindex" );

        return renderView( view="/errors/notFound", args=args );
    }
}
```

#### Defining a layout template

The default layout template for the 404 is your site's default layout, i.e. "Main" (`/application/layouts/Main.cfm`). If you wish to configure a different default layout template for your 404 template, you can do so with the `notFoundLayout` configuration option, i.e.

```luceescript
// /application/config/Config.cfc
component extends="preside.system.config.Config" {

    public void function configure() {
        super.configure();

        // other settings...

        settings.notFoundLayout  = "404Layout";
        settings.notFoundViewlet = "errors.my404Viewlet";
    }
}
```

You can also programatically set the layout for your 404 template in your handler (you may wish to dynamically pick the layout depending on a number of variables):

```luceescript
// /application/handlers/Errors.cfc
component {

    private string function notFound( event, rc, prc, args={} ) {
        event.setHTTPHeader( statusCode="404" );
        event.setHTTPHeader( name="X-Robots-Tag", value="noindex" );
        event.setLayout( "404Layout" );

        return renderView( view="/errors/notFound", args=args );
    }
}
```

### Programatically responding with a 404

If you ever need to programatically respond with a 404 status, you can use the `event.notFound()` method to do so. This method will ensure that the 404 statuscode header is set and will render your configured 404 template for you. For example:

```luceescript
// someHandler.cfc
component {

    public void function index( event, rc, prc ) {
        prc.record = getModel( "someService" ).getRecord( rc.id ?: "" );

        if ( !prc.record.recordCount ) {
            event.notFound();
        }

        // .. carry on processing the page
    }
}
```

### Direct access to the 404 template

The 404 template can be directly accessed by visiting /404.html. This is achieved through a custom route dedicated to error pages (see [[routing]]).

This is particular useful for rendering the 404 template in cases where PresideCMS is not producing the 404. For example, you may be serving static assets directly through Tomcat and want to see the custom 404 template when one of these assets is missing. To do this, you would edit your `${catalina_home}/config/web.xml` file to define a rewrite URL for 404s:

```xml
<!-- ... -->

        <welcome-file-list>
        <welcome-file>index.cfm</welcome-file>
    </welcome-file-list>

    <error-page>
        <error-code>404</error-code>
        <location>/404.html</location>
    </error-page>

</web-app>
```

Another example is producing 404 responses for secured areas of the application. In PresideCMS's default urlrewrite.xml file (that works with Tuckey URL Rewrite), we block access to files such as Application.cfc by responding with a 404:

```xml
<rule>
    <name>Block access to certain URLs</name>
    <note>
        All the following requests should not be allowed and should return with a 404:

        * the application folder (where all the logic and views for your site lives)
        * the uploads folder (should be configured to be somewhere else anyways)
        * this url rewrite file!
        * Application.cfc
    </note>
    <from>^/(application/|uploads/|urlrewrite\.xml\b|Application\.cfc\b)</from>
    <set type="status">404</set>
    <to last="true">/404.html</to>
</rule>
```

## 401 Access denied pages

Access denied pages can be created and used in exactly the same way as 404 pages, with a few minor differences. The page can be invoked with `event.accessDenied( reason=deniedReason )` and will be automatically invoked by the core access control system when a user attempts to access pages and assets to which they do not have permission.

>>>>>> For a more in depth look at front end user permissioning and login, see [[websiteusersandpermissioning]].

### Creating a 401 template

The 401 template is implemented as a Preside Viewlet (see [[viewlets]]) and a core implementation already exists. The name of the viewlet is configured in your application's Config.cfc with the `accessDeniedViewlet` setting. The default is "errors.accessDenied":

```luceescript
// /application/config/Config.cfc
component extends="preside.system.config.Config" {

    public void function configure() {
        super.configure();

        // other settings...
        settings.accessDeniedViewlet = "errors.accessDenied";
    }
}
```

The viewlet will be passed an `args.reason` argument that will be either `LOGIN_REQUIRED`, `INSUFFICIENT_PRIVILEGES` or any other codes that you might make use of.

The core implementation sets the 401 header and then renders a different view, depending on the access denied reason:

```luceescript
// /preside/system/handlers/Errors.cfc
component {

    private string function accessDenied( event, rc, prc, args={} ) {
        event.setHTTPHeader( statusCode="401" );
        event.setHTTPHeader( name="X-Robots-Tag"    , value="noindex" );
        event.setHTTPHeader( name="WWW-Authenticate", value='Website realm="website"' );

        switch( args.reason ?: "" ){
            case "INSUFFICIENT_PRIVILEGES":
                return renderView( view="/errors/insufficientPrivileges", args=args );
            default:
                return renderView( view="/errors/loginRequired", args=args );
        }
    }
}
```

For simple cases, you will only need to override the `/errors/insufficientPrivileges` and/or `/errors/loginRequired` view by creating them in your application's view folder, e.g.

```lucee
<!-- /application/views/errors/insufficientPrivileges.cfm -->
<h1>Name's not on the door, you ain't coming in</h1>
<p> Some pithy remark.</p>
```

```lucee
<!-- /application/views/errors/loginRequired.cfm -->
#renderViewlet( event="login.loginPage", message="LOGIN_REQUIRED" )#
```

#### Implementing handler logic

If you wish to perform some handler logic for your 401 template, you can simply create the Errors.cfc handler file and implement the "accessDenied" action. For example:

```luceescript
// /application/handlers/Errors.cfc
component {
    private string function accessDenied( event, rc, prc, args={} ) {
        event.setHTTPHeader( statusCode="401" );
        event.setHTTPHeader( name="X-Robots-Tag"    , value="noindex" );
        event.setHTTPHeader( name="WWW-Authenticate", value='Website realm="website"' );

        switch( args.reason ?: "" ){
            case "INSUFFICIENT_PRIVILEGES":
                return renderView( view="/errors/my401View", args=args );
            case "MY_OWN_REASON":
                return renderView( view="/errors/custom401", args=args );
            default:
                return renderView( view="/errors/myLoginFormView", args=args );
        }
    }
}
```

#### Defining a layout template

The default layout template for the 401 is your site's default layout, i.e. "Main" (/application/layouts/Main.cfm). If you wish to configure a different default layout template for your 401 template, you can do so with the `accessDeniedLayout` configuration option, i.e.

```luceescript
// /application/config/Config.cfc
component extends="preside.system.config.Config" {

    public void function configure() {
        super.configure();

        // other settings...

        settings.accessDeniedLayout  = "401Layout";
        settings.accessDeniedViewlet = "errors.my401Viewlet";
    }
}
```

You can also programatically set the layout for your 401 template in your handler (you may wish to dynamically pick the layout depending on a number of variables):

```luceescript
// /application/handlers/Errors.cfc
component {
    private string function accessDenied( event, rc, prc, args={} ) {
        event.setHTTPHeader( statusCode="401" );
        event.setHTTPHeader( name="X-Robots-Tag"    , value="noindex" );
        event.setHTTPHeader( name="WWW-Authenticate", value='Website realm="website"' );

        event.setLayout( "myCustom401Layout" );

        // ... etc.
    }
}
```

### Programatically responding with a 401

If you ever need to programatically respond with a 401 access denied status, you can use the `event.accessDenied( reason="MY_REASON" )` method to do so. This method will ensure that the 401 statuscode header is set and will render your configured 401 template for you. For example:

```luceescript
// someHandler.cfc
component {

    public void function reservePlace( event, rc, prc ) {
        if ( !isLoggedIn() ) {
            event.accessDenied( reason="LOGIN_REQUIRED" );
        }
        if ( !hasWebsitePermission( "events.reserveplace" ) ) {
            event.accessDenied( reason="INSUFFICIENT_PRIVILEGES" );
        }

        // .. carry on processing the page
    }
}
```

## 500 Error Pages

The implementation of 500 error pages is more straight forward than the 40x templates and involves only creating a flat `500.htm` file in your webroot. The reason behind this is that a server error may be caused by your site's layout code, or may even occur before PresideCMS code is called at all; in which case the code to render your error template will not be available.

If you do not create a `500.htm` in your webroot, PresideCMS will use its own default template for errors. This can be found at `/preside/system/html/500.htm`.

### Bypassing the error template

In your local development environment, you will want to be able see the details of errors, rather than view a simple error message. This can be achieved with the config setting, `showErrors`:

```luceescript
// /application/config/Config.cfc
component extends="preside.system.config.Config" {

    public void function configure() {
        super.configure();

        // other settings...

        settings.showErrors = true;
    }
}
```

In most cases however, you will not need to configure this for your local environment. PresideCMS uses ColdBox's environment configuration to configure a "local" environment that already has `showErrors` set to **true** for you. If you wish to override that setting, you can do so by creating your own "local" environment function:

```luceescript
// /application/config/Config.cfc
component extends="preside.system.config.Config" {

    public void function configure() {
        super.configure();

        // other settings...
    }

    public void function local() {
        super.local();

        settings.showErrors = false;
    }
}
```

>>> PresideCMS's built-in local environment configuration will map URLs like "mysite.local", "local.mysite", "localhost" and "127.0.0.1" to the "local" environment.

## 503 Maintenance mode page

The administrator interface provides a simple GUI for putting the site into maintenance mode (see figure below). This interface allows administrators to enter a custom title and message, turn maintenance mode on/off and also to supply custom settings to allow users to bypass maintenance mode.

![Screenshot of maintenance mode management GUI](images/screenshots/maintenance_mode.png)

### Creating a custom 503 page

The 503 template is implemented as a Preside Viewlet (see [[viewlets]]) and a core implementation already exists. The name of the viewlet is configured in your application's Config.cfc with the `maintenanceModeViewlet` setting. The default is "errors.maintenanceMode":

```luceescript
// /application/config/Config.cfc
component extends="preside.system.config.Config" {

    public void function configure() {
        super.configure();

        // other settings...
        settings.maintenanceModeViewlet = "errors.maintenanceMode";
    }
}
```

To create a custom template, you can choose either to provide your own viewlet by changing the config setting, or by overriding the view and/or handler of the `errors.maintenanceMode` viewlet.

For example, in your site's `/application/views/errors/` folder, you could create a `maintenanceMode.cfm` file with the following:

```html
<cfparam name="args.title"   />
<cfparam name="args.message" />

<cfoutput><!DOCTYPE html>
<html>
    <head>
        <title>#args.title#</title>
        <meta charset="utf-8">
        <meta name="robots" content="noindex,nofollow" />
    </head>
    <body>
        <h1>#args.title#</h1>
        #args.message#
    </body>
</html></cfoutput>
```

>>>>>> The maintenance mode viewlet needs to render the entire HTML of the page.

### Manually clearing maintenance mode

You may find yourself in a situation where you application is in maintenance mode and you have no means by which to access the admin because the password has been lost. In this case, you have two options:

#### Method 1: Set bypass password directly in the database

To find the current bypass password, you can query the database with:

```sql
select value
from   psys_system_config
where  category = 'maintenanceMode'
and    setting  = 'bypass_password';
```

If the value does not exist, create it with:

```sql
insert into psys_system_config (id, category, setting, `value`, datecreated, datemodified)
values( '{a unique id}', 'maintenancemode', 'bypass_password', '{new password}', now(), now() );
```

The bypass password can then be used by supplying it as a URL parameter to your site, e.g. `http://www.mysite.com/?thepassword`. From there, you should be able to login to the administrator and turn off maintenance mode.

#### Method 2: Delete the maintenance mode file

When maintenance mode is activated, a file is created at `/yoursite/application/config/.maintenance`. To clear maintenance mode, delete that file and restart the application.
