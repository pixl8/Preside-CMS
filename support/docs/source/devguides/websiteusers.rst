Website users and permissioning
===============================

.. contents:: :local:

Overview
########

PresideCMS supplies a basic core system for setting up user logins and permissioning for your front end websites. This system includes:

* Membership management screens in the administrator
* Ability to create users and user "benefits" (synonymous with user groups)
* Ability to apply access restrictions to site pages and assets through user benefits and individual users
* Core system for dealing with access denied responses (see :ref:`custom-error-pages-401`)
* Core handlers for processing login, logout and forgotten password

The expectation is that, for more involved sites, these core systems will be extended and interacted with to create a fuller membership experience.

Users and Benefits
##################

We provide a simple model of **users** and **benefits** with two core preside objects, :doc:`/reference/presideobjects/website_user` and :doc:`/reference/presideobjects/website_benefit`. A user can have multiple benefits. User benefit's are analogous to user groups.

.. note::
    
    We have kept the fields for both objects to a bare minimum so as to not impose unwanted logic to your sites. You are encouraged to extend these objects to add your site specific data needs (see :ref:`presideobjectsextending`).

Login
#####

The user object (see :doc:`/reference/presideobjects/website_user`) provides core fields for handling login and displaying the currently logged in user's name:

* :code:`login_id`
* :code:`email_address`
* :code:`password`
* :code:`display_name`

Passwords are hashed using BCrypt and the default login procedure checks the supplied login id for a match against either the `login_id` or `email_address` field before checking the validity of the password with BCrypt.

The core login logic can be found in the :doc:`/reference/api/websiteloginservice`.

Core handler actions
--------------------

In addition to the core service logic, PresideCMS also provides a thin handler layer for processing login and logout and for rendering a login page. The handler can be found at :code:`/system/handlers/Login.cfc`. It provides the following direct actions and viewlets:

Default (index)
~~~~~~~~~~~~~~~

The default action will render the loginPage viewlet. It will also redirect the user if they are already logged in. You can access this action with the URL: mysite.com/login/ (generate the URL with :code:`event.buildLink( linkTo="login" )`).

AttemptLogin
~~~~~~~~~~~~

The :code:`attemptLogin()` action will process a login attempt, redirecting to the default action on failure or redirecting to the last page accessed (or the default post login page if no last page can be calculated) on success. You can use :code:`event.buildLink( linkTo='login.attemptLogin' )` to build the URL required to access this action.

The action expects the required POST parameters :code:`loginId` and :code:`password` and will also process the optional fields :code:`rememberMe` and :code:`postLoginUrl`.

Logout
~~~~~~

The :code:`logout()` action logs the user out of their session and redirects them either to the previous page or, if that cannot be calculated, to the default post logout page.

You can build a logout link with :code:`event.buildLink( linkTo='login.logout' )`.

Viewlet: loginPage
~~~~~~~~~~~~~~~~~~

The :code:`loginPage` viewlet is intended to render the login page. 

The core view for this viewlet is just a stub and requires a specific implementation per site (see :ref:`websiteusersloginexample` below).

The core handler ensures that the following arguments are passed to the view:

============================ =================================================================================================================================
:code:`args.allowRememberMe` Whether or not remember me functionality is allowed
:code:`args.postLoginUrl`    URL to redirect the user to after successful login
:code:`args.loginId`         Login id that the user entered in their last login attempt (if any)
:code:`args.rememberMe`      Remember me preference that the user chose in their last login attempt (if any)
:code:`args.message`         Message ID that can be used to render a message to the user. Core message IDs are :code:`LOGIN_REQUIRED` and :code:`LOGIN_FAILED`
============================ =================================================================================================================================

.. note::

    The default implementation of the access denied error handler renders this viewlet when the cause of the access denial is "LOGIN_REQUIRED" so that your login form will automatically be shown when login is required to access some resource. See :ref:`custom-error-pages-401` for more detail.


.. _websiteusersloginexample:

Example login page implementation
---------------------------------

The bare minimum requirement to creating a working login system is to create a view that will render your login form. This view will be part of the :code:`login.loginPage` viewlet, so will need to live at :code:`/yoursite/application/views/login/loginPage.cfm`:

.. code-block:: cfm

    <cfparam name="args.loginId"         default="" />
    <cfparam name="args.password"        default="" />
    <cfparam name="args.rememberMe"      default="" />
    <cfparam name="args.postLoginUrl"    default="" />
    <cfparam name="args.message"         default="" />
    <cfparam name="args.allowRememberMe" default=getSystemSetting( "website_users", "allow_remember_me", true ) />

    <cfoutput>
        <!--- display an alert message based on the args.message parameter --->
        <cfswitch expression="#args.message#">
            <cfcase value="LOGIN_REQUIRED">
                <p class="alert-message">The resource you are attempting to access requires a secure login. Please login using the form below, or register using the links to the right.</p>
            </cfcase>
            <cfcase value="LOGIN_FAILED">
                <p class="alert-message">The email address and password combination you supplied did not match our records. Please try again.</p>
            </cfcase>
        </cfswitch>

        <h2>Member Login</h2>

        <!--- the form action needs to be the the login.attemptLogin handler action --->
        <form action="#event.buildLink( linkTo="login.attemptLogin" )#" method="post">
            <!--- include the postLoginUrl so that it can be maintained across login attempts --->
            <input type="hidden" name="postLoginUrl" value="#args.postLoginUrl#" />

            <!--- the core login.attemptLogin handler action expects a 'loginId' field --->
            <label for="loginId">Email address <span class="required">*</span></label>
            <input type="email" id="loginId" name="loginId" value="#args.loginId#" class="form-control">
                                        
            <!--- the core login.attemptLogin handler action expects a 'password' field --->
            <label for="password">Password <span class="required">*</span></label>
            <input type="password" id="password" name="password" class="form-control">

            <!--- only show remember me checkbox if the feature is enabled --->
            <cfif args.allowRememberMe>
                <input type="checkbox" name="rememberMe" id="rememberMe" value="1"<cfif IsBoolean( args.rememberMe ) and args.rememberMe> checked="checked"</cfif>>
                <label for="rememberMe">Keep me logged in</label>
            </cfif>
            
            <input type="submit" value="Log in">
        </form>
    </cfoutput>

Checking login and getting logged in user details
-------------------------------------------------

You can check the logged in status of the current user with the helper method, :code:`isLoggedIn()`. Additionally, you can check whether the current user is only auto logged in from a cookie with, :code:`isAutoLoggedIn()`. User details can be retrieved with the helper methods :code:`getLoggedInUserId()` and :code:`getLoggedInUserDetails()`.

For example:

.. code-block:: java

    // an example 'add comment' handler:
    public void function addCommentAction( event, rc, prc ) output=false {
        if ( !isLoggedIn() || isAutoLoggedIn() ) {
            event.accessDenied( "LOGIN_REQUIRED" );
        }

        var userId       = getLoggedInUserId();
        var emailAddress = getLoggedInUserDetails().email_address ?: "";

        // ... etc.
    }



Permissions
###########

A permission is something that a user can do within the website. PresideCMS comes with two permissions out of the box, the ability to access a restricted page and the ability to access a restricted asset. These are configured in :code:`Config.cfc` with the :code:`settings.websitePermissions` struct:

.. code-block:: java

    // /preside/system/config/Config.cfc
    component output=false {

        public void function configure() output=false {
            // ... other settings ... //

            settings.websitePermissions = {
                  pages  = [ "access" ]
                , assets = [ "access" ]
            };

            // ... other settings ... //

        }

    }

The core settings above produces two permission keys, "pages.access" and "assets.access", these permission keys are used in creating and checking applied permissions (see below). The permissions can also be directly applied to a given user or benefit in the admin UI:

.. figure:: /images/website_benefit_form.png

    Screenshot of the default edit benefit form. Benefits can have permissions directly applied to them.

The title and description of a permission key are defined in :code:`/i18n/permissions.properties`:

.. code-block:: properties

    # ... other keys ...

    pages.access.title=Access restricted pages
    pages.access.description=Users can view all restricted pages in the site tree unless explicitly denied access to them

    assets.access.title=Access restricted assets
    assets.access.description=Users can view or download all restricted assets in the asset tree unless explicitly denied access to them

Applied permissions and contexts
--------------------------------

Applied permissions are instances of a permission that are granted or denied to a particular user or benefit. These instances are stored in the :doc:`/reference/presideobjects/website_applied_permission` preside object.

Contexts
~~~~~~~~

In addition to being able to set a grant or deny permission against a user or benefit, applied permissions can also be given a **context** and **context key** to create more refined permission schemes. 

For instance, when you grant or deny access to a user for a particular **page** in the site tree, you are creating a grant or deny instance with a context of "page" and a context key that is the id of the page. 


Defining your own custom permissions
------------------------------------

It is likely that you will want to define your own permissions for your site. Examples might be the ability to add comments, or upload documents. Creating the permission keys requires modifying both your site's Config.cfc and permissions.properties files:

.. code-block:: java

    // /mysite/application/config/Config.cfc
    component output=false extends="preside.system.config.Config" {

        public void function configure() output=false {
            super.configure();

            // ... other settings ... //

            settings.websitePermissions.comments = [ "add", "edit" ];
            settings.websitePermissions.documents = [ "upload" ];

            // ... other settings ... //

        }

    }

The settings above would produce three keys, :code:`comments.add`, :code:`comments.edit` and :code:`documents.upload`.

.. code-block:: properties

    # /mysite/application/i18n/permissions.properties

    comments.add.title=Add comments
    comments.add.description=Ability to add comments in our comments system

    comments.edit.title=Edit comments
    comments.edit.description=Ability to edit their own comments after they have been submitted

    documents.upload.title=Upload documents
    documents.upload.description=Ability to upload documents to share with other privileged members

With the permissions configured as above, the benefit or user edit screen would appear with the new permissions added:

.. figure:: /images/website_benefit_form_extended.png

    Screenshot of the edit benefit form with custom permissions added.

Checking permissions
--------------------

.. note::

    The core system already implements permission checking for restricted site tree page access and restricted asset access. You should only require to check permissions for your own custom permission schemes.

You can check to see whether or not the currently logged in user has a particular permission with the :code:`hasWebsitePermission()` helper method. The minimum usage is to pass only the permission key:

.. code-block:: cfm

    <cfif hasWebsitePermission( "comments.add" )>
        <button>Add comment</button>
    </cfif>

You can also check a specific context by passing in the :code:`context` and :code:`contextKeys` arguments:

.. code-block:: java

    public void function addCommentAction( event, rc, prc ) output=false {
        var hasPermission = hasWebsitePermission(
              permissionKey = "comments.add"
            , context       = "commentthread"
            , contextKeys   = [ rc.thread ?: "" ]
        );
        
        if ( !hasPermission ) {
            event.accessDenied( reason="INSUFFIENCT_PRIVILEGES" );
        }
    }

.. note::

    When checking a context permission, you pass an array of context keys to the :code:`hasWebsitePermission()` method. The returned grant or deny permission will be the one associated with the first found context key in the array. 

    This allows us to implement cascading permission schemes. For site tree access permissions for example, we pass an array of page ids. The first page id is the current page, the next id is it's parent, and so on.