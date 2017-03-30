---
id: websiteusersandpermissioning
title: Website users and permissioning
---

## Overview

PresideCMS supplies a basic core system for setting up user logins and permissioning for your front end websites. This system includes:

* Membership management screens in the administrator
* Ability to create users and user "benefits" (synonymous with user groups)
* Ability to apply access restrictions to site pages and assets through user benefits and individual users
* Core system for dealing with access denied responses
* Core handlers for processing login, logout and forgotten password

The expectation is that, for more involved sites, these core systems will be extended and interacted with to create a fuller membership experience.

## Users and Benefits

We provide a simple model of **users** and **benefits** with two core preside objects, `website_user` and `website_benefit`. A user can have multiple benefits. User benefits are analogous to user groups.

>>> We have kept the fields for both objects to a bare minimum so as to not impose unwanted logic to your sites. You are encouraged to extend these objects to add your site specific data needs.

## Login

The `website_user` object provides core fields for handling login and displaying the currently logged in user's name:

* `login_id`
* `email_address`
* `password`
* `display_name`

Passwords are hashed using BCrypt and the default login procedure checks the supplied login id for a match against either the `login_id` or `email_address` field before checking the validity of the password with BCrypt.

### Core handler actions

In addition to the core service logic, PresideCMS also provides a thin handler layer for processing login and logout and for rendering a login page. The handler can be found at `/system/handlers/Login.cfc`. It provides the following direct actions and viewlets:

#### Default (index)

The default action will render the loginPage viewlet. It will also redirect the user if they are already logged in. You can access this action with the URL: mysite.com/login/ (generate the URL with `event.buildLink( linkTo="login" )`).

#### AttemptLogin

The `attemptLogin()` action will process a login attempt, redirecting to the default action on failure or redirecting to the last page accessed (or the default post login page if no last page can be calculated) on success. You can use `event.buildLink( linkTo='login.attemptLogin' )` to build the URL required to access this action.

The action expects the required POST parameters `loginId` and `password` and will also process the optional fields `rememberMe` and `postLoginUrl`.

#### Logout

The `logout()` action logs the user out of their session and redirects them either to the previous page or, if that cannot be calculated, to the default post logout page.

You can build a logout link with `event.buildLink( linkTo='login.logout' )`.

#### Viewlet: loginPage

The `loginPage` viewlet is intended to render the login page. 

The core view for this viewlet is just an example and should probably be overwritten within your application. However it should show how things could be implemented.

The core handler ensures that the following arguments are passed to the view:

<div class="table-responsive">
    <table class="table">
        <thead>
            <tr>
                <th>Name</th>
                <th>Descriptiojn</th>
            </tr>
        </thead>
        <tbody>
            <tr><td>`args.allowRememberMe`</td> <td>Whether or not remember me functionality is allowed</td>
            <tr><td>`args.postLoginUrl`</td>    <td>URL to redirect the user to after successful login</td>
            <tr><td>`args.loginId`</td>         <td>Login id that the user entered in their last login attempt (if any)</td>
            <tr><td>`args.rememberMe`</td>      <td>Remember me preference that the user chose in their last login attempt (if any)</td>
            <tr><td>`args.message`</td>         <td>Message ID that can be used to render a message to the user. Core message IDs are `LOGIN_REQUIRED` and `LOGIN_FAILED`            </td>
        </tbody>
    </table>
</div>

>>> The default implementation of the access denied error handler renders this viewlet when the cause of the access denial is "LOGIN_REQUIRED" so that your login form will automatically be shown when login is required to access some resource.

### Checking login and getting logged in user details

You can check the logged in status of the current user with the helper method, `isLoggedIn()`. Additionally, you can check whether the current user is only auto logged in from a cookie with, `isAutoLoggedIn()`. User details can be retrieved with the helper methods `getLoggedInUserId()` and `getLoggedInUserDetails()`.

For example:

```luceescript
// an example 'add comment' handler:
public void function addCommentAction( event, rc, prc ) {
    if ( !isLoggedIn() || isAutoLoggedIn() ) {
        event.accessDenied( "LOGIN_REQUIRED" );
    }

    var userId       = getLoggedInUserId();
    var emailAddress = getLoggedInUserDetails().email_address ?: "";

    // ... etc.
}
```

### Login impersonation

CMS administrative users, with sufficient privileges, are able to "impersonate" the login of website users through the admin GUI. Once they have done this, they are treated as a fully logged in user in the front end.

If you wish to restrict these impersonated logins in any way, you can use the `isImpersonated()` method of the `websiteLoginService` object to check to see whether or not the current login is merely an impersonated one.

## Permissions

A permission is something that a user can do within the website. PresideCMS comes with two permissions out of the box, the ability to access a restricted page and the ability to access a restricted asset. These are configured in `Config.cfc` with the `settings.websitePermissions` struct:

```luceescript
// /preside/system/config/Config.cfc
component {

    public void function configure() {
        // ... other settings ... //

        settings.websitePermissions = {
              pages  = [ "access" ]
            , assets = [ "access" ]
        };

        // ... other settings ... //

    }

}
```

The core settings above produces two permission keys, "pages.access" and "assets.access", these permission keys are used in creating and checking applied permissions (see below). The permissions can also be directly applied to a given user or benefit in the admin UI:

![Screenshot of the default edit benefit form. Benefits can have permissions directly applied to them.](images/screenshots/website_benefit_form.png)


The title and description of a permission key are defined in `/i18n/permissions.properties`:

```properties
# ... other keys ...

pages.access.title=Access restricted pages
pages.access.description=Users can view all restricted pages in the site tree unless explicitly denied access to them

assets.access.title=Access restricted assets
assets.access.description=Users can view or download all restricted assets in the asset tree unless explicitly denied access to them
```

### Applied permissions and contexts

Applied permissions are instances of a permission that are granted or denied to a particular user or benefit. These instances are stored in the `website_applied_permission` preside object.

#### Contexts

In addition to being able to set a grant or deny permission against a user or benefit, applied permissions can also be given a **context** and **context key** to create more refined permission schemes. 

For instance, when you grant or deny access to a user for a particular **page** in the site tree, you are creating a grant or deny instance with a context of "page" and a context key that is the id of the page. 


### Defining your own custom permissions

It is likely that you will want to define your own permissions for your site. Examples might be the ability to add comments, or upload documents. Creating the permission keys requires modifying both your site's Config.cfc and permissions.properties files:

```luceescript
// /mysite/application/config/Config.cfc
component extends="preside.system.config.Config" {

    public void function configure() {
        super.configure();

        // ... other settings ... //

        settings.websitePermissions.comments = [ "add", "edit" ];
        settings.websitePermissions.documents = [ "upload" ];

        // ... other settings ... //

    }

}
```

The settings above would produce three keys, `comments.add`, `comments.edit` and `documents.upload`.

```properties
# /mysite/application/i18n/permissions.properties

comments.add.title=Add comments
comments.add.description=Ability to add comments in our comments system

comments.edit.title=Edit comments
comments.edit.description=Ability to edit their own comments after they have been submitted

documents.upload.title=Upload documents
documents.upload.description=Ability to upload documents to share with other privileged members

With the permissions configured as above, the benefit or user edit screen would appear with the new permissions added:
```

![Screenshot of the edit benefit form with custom permissions added.](images/screenshots/website_benefit_form_extended.png)

### Checking permissions

>>> The core system already implements permission checking for restricted site tree page access and restricted asset access. You should only require to check permissions for your own custom permission schemes.

You can check to see whether or not the currently logged in user has a particular permission with the `hasWebsitePermission()` helper method. The minimum usage is to pass only the permission key:

```lucee
<cfif hasWebsitePermission( "comments.add" )>
    <button>Add comment</button>
</cfif>
```

You can also check a specific context by passing in the `context` and `contextKeys` arguments:

```luceescript
public void function addCommentAction( event, rc, prc ) {
    var hasPermission = hasWebsitePermission(
          permissionKey = "comments.add"
        , context       = "commentthread"
        , contextKeys   = [ rc.thread ?: "" ]
    );
    
    if ( !hasPermission ) {
        event.accessDenied( reason="INSUFFIENCT_PRIVILEGES" );
    }
}
```

>>> When checking a context permission, you pass an array of context keys to the `hasWebsitePermission()` method. The returned grant or deny permission will be the one associated with the first found context key in the array.

>>>This allows us to implement cascading permission schemes. For site tree access permissions for example, we pass an array of page ids. The first page id is the current page, the next id is its parent, and so on.

## Partial restrictions in site tree pages

The site tree pages system allows you to define that a page is "Partially restricted". You can check that a user does not have full access to a partially restricted page with `event.isPagePartiallyRestricted()`. This then allows you to implement alternative content to show when the user does not have full access. It is down to you to implement this alternative content. A simple example:

```lucee
<!-- /views/page-types/standard_page/index.cfm -->

<cfif event.isPagePartiallyRestricted()>
    #renderView( "/general/_partiallyRestricted" )
<cfelse>
    #args.main_content#
</cfif>
```
