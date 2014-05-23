Permissioning
=============

Permissioning is split into three distinct concepts in PresideCMS:

Permissions and roles
    These are defined in configuration and are not editable through the CMS GUI.

        - **Permissions** allow you to grant or deny access to a particular action
        - **Roles** provide convenient grant access to one or more permissions

Users and groups
    User's and groups are defined through the administrative GUI and are stored in the database.

        - An *active* **user** must belong to one or more groups
        - A **group** must have one or more *roles*

    Permissions are granted to a user through the roles that are associated with the groups that she belongs to.

Contextual permissions
    Contextual permissions are fine grained permissions implemented specifically for any given area of the CMS that requires them.

    For example, you could deny the "*Freelancers*" user group the "*Add pages*" permission for a particular page and its children in the sitetree; in this case, the context is the ID of the page.

    Contextual permissions are granted or denied to user **groups** and always take precedence over permissions granted through groups and roles.

    .. note::

        If a feature of the CMS requires context permissions, it must supply its own GUI for managing them.

Configuring permissions and roles
#################################

Permissions and roles are configured in your site or extension's :doc:`Config.cfc <configcfc>` file. An example configuration might look like this:

.. code-block:: js

    public void function configure() output=false {
        super.configure();

    // PERMISSIONS
        // here we define a feature, "analytics dashboard" with a number of permissions
        settings.permissions.analyticsdashboard = [ "navigate", "share", "configure" ];

        // features can be organised into sub-features to any depth, here
        // we have a depth of two, i.e. "eventmanagement.events"
        settings.permissions.eventmanagement = {
              events = [ "navigate", "view", "add", "edit", "delete" ]
            , prices = [ "navigate", "view", "add", "edit", "delete" ]
        };

        /* The settings above will translate to the following permission keys being
           available for use in your Railo code, i.e. if ( hasPermission( userId, permissionKey ) ) {...}:

           analyticsdashboard.navigate
           analyticsdashboard.share
           analyticsdashboard.configure

           eventmanagement.events.navigate
           eventmanagement.events.view
           eventmanagement.events.add
           eventmanagement.events.edit
           eventmanagement.events.delete

           eventmanagement.prices.navigate
           eventmanagement.prices.view
           eventmanagement.prices.add
           eventmanagement.prices.edit
           eventmanagement.prices.delete
        */

    // ROLES
        // roles are simply a named array of permission keys
        // permission keys for roles can be defined with wildcards (*)
        // and can be excluded with the ! character:

        // define a new role, with all event management perms except for delete
        settings.roles.eventsOrganiser = [ "eventmanagement.*", "!*.delete" ];

        // another new role specifically for analytics viewing
        settings.roles.analyticsViewer = [ "analyticsdashboard.navigate", "analyticsdashboard.share" ];

        // add some new permissions to some existing core roles
        settings.roles.administrator = settings.roles.administrator ?: [];
        settings.roles.administrator.append( "eventmanagement.*" );
        settings.roles.administrator.append( "analyticsdashboard.*" );

        settings.roles.someRole = settings.roles.someRole ?: [];

Defining names and descriptions (i18n)
--------------------------------------

Names and descriptions for your roles and permissions must be defined in i18n resource bundles.

For roles, you should add *name* and *description* keys for each role to the :code:`/i18n/roles.properties` file, e.g.

.. code-block:: properties

    eventsOrganiser.title=Events organiser
    eventsOrganiser.description=The event organiser role grants aspects to all aspects of event management in the CMS except for deleting records (which must be done by the administrator)

    analyticsViewer.title=Analytics viewer
    analyticsViewer.description=The analytics viewer role grants permission to view statistics in the analytics dashboard

For permissions, add your keys to the :code:`/i18n/permissions.properties` file, e.g.


.. code-block:: properties

    eventmanagement.events.navigate.title=Events management navigation
    eventmanagement.events.navigate.description=View events management navigation links

    eventmanagement.events.view=title=View events
    eventmanagement.events.view=description=View details of events that have been entered into the system

.. note::

    For permissions, you may only want to create resource bundle entries when the permissions will be used in contextual permission GUIs. Otherwise, the translations will never be used.
