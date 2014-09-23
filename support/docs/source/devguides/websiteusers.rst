Website users and permissioning
===============================

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

Applied permissions are instances of a permission that are granted or denied to a particular user or benefit. These permissions are stored in the :doc:`/reference/presideobjects/website_applied_permission` preside object.

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

You can however, also check a specific context by passing in the :code:`context` and :code:`contextKeys` arguments:

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