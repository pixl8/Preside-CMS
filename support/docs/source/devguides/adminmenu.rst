Modifying the administrator left hand menu
==========================================

Overview
########

PresideCMS provides a simple mechanism for configuring the left hand menu of the administrator, either to add new main navigational sections, take existing ones away or to modify the order of menu items.

Configuration
#############

Each top level item of the menu is stored in an array that is set in :code:`settings.adminSideBarItems` in :code:`Config.cfc`. The core implementation looks like this:

.. code-block:: java

    component output=false {

        public void function configure() output=false {
            
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

Each of these side bar items is then implemented as a view that lives under a :code:`/views/admin/layout/sidebar/` folder. For example, for the 'sitetree' item, there exists a view at :code:`/views/admin/layout/sidebar/sitetree.cfm` that looks like this:

.. code-block:: java

    // /views/admin/layout/sidebar/sitetree.cfm

    if ( hasCmsPermission( "sitetree.navigate" ) ) {
        WriteOutput( renderView(
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

Core view helpers
#################

There are two core views that can be used when rendering your menu items, :code:`/admin/layout/sidebar/_menuItem` and :code:`/admin/layout/sidebar/_subMenuItem`.

/admin/layout/sidebar/_menuItem
-------------------------------

Renders a top level menu item.

Arguments
~~~~~~~~~

============= =================================================================================================================================================================================
Argument      Description
============= =================================================================================================================================================================================
active        Boolean. Whether or not the current page lives within this part of the CMS.
link          Where this menu item points to. Not needed when the menu item has a submenu.
title         Title of the menu item
icon          Icon class for the menu item. We use font awesome, so "fa-users" for example.
subMenu       Rendered submenu items.
subMenuItems  Array of sub menu items to render (alternative to supplying a rendered sub menu). Each item should be a struct with :code:`link`, :code:`title` and optional :code:`gotoKey` keys
gotoKey       Optional key that when used in combination with the :code:`g` key, will send the user to the item's link. e.g. :code:`g+s` takes you to the site tree.
============= =================================================================================================================================================================================

Example
~~~~~~~

.. code-block:: cfm

    <cfset subMenuItems = [] />
    <cfif hasCmsPermission( "mynewsubfeature.access" )>
        <cfset subMenuItems.append( {
              link  = event.buildAdminLink( linkTo="mynewsubfeature" ) 
            , title = event.translateResource( uri="mynewsubfeature.menu.title" )
        } ) />
    </cfif>
    <cfif hasCmsPermission( "myothernewsubfeature.access" )>
        <cfset subMenuItems.append( {
              link  = event.buildAdminLink( linkTo="myothernewsubfeature" ) 
            , title = event.translateResource( uri="myothernewsubfeature.menu.title" )
        } ) />
    </cfif>


    #renderView( view="/admin/layout/sidebar/_menuItem", args={
          active       = ReFindNoCase( "my(other)?newsubfeature$", event.getCurrentHandler() )
        , title        = event.translateResource( uri="mynewfeature.menu.title" )
        , icon         = "fa-world-domination"
        , subMenuItems = subMenuItems
    } )#

/admin/layout/sidebar/_subMenuItem
----------------------------------

Renders a sub menu item.

Arguments
~~~~~~~~~

============= =================================================================================================================================================================================
Argument      Description
============= =================================================================================================================================================================================
link          Where this menu item points to.
title         Title of the menu item
gotoKey       Optional key that when used in combination with the :code:`g` key, will send the user to the item's link. e.g. :code:`g+s` takes you to the site tree.
============= =================================================================================================================================================================================

Example
~~~~~~~

.. code-block:: cfm

    <cfif hasCmsPermission( "mynewsubfeature.access" )>
        #renderView( view="/admin/layout/sidebar/_subMenuItem", args={
              link    = event.buildAdminLink( linkTo="mynewsubfeature" )
            , title   = event.translateResource( uri="mynewsubfeature.menu.title" )
            , gotoKey = "f"
        } )#
    </cfif>


Examples
########

Adding a new item
-----------------

Firstly, add the item to our array of sidebar items in your site or extension's Config.cfc:

.. code-block:: java

    // ...

    settings.adminSideBarItems.append( "mynewfeature" );

    // ...

Finally, create the view for the side bar item:

.. code-block:: cfm

    <!--- /views/admin/layout/sidebar/mynewfeature.cfm --->
    <cfif hasCmsPermission( "mynewfeature.access" )>
        <cfoutput>
            #renderView( view="/admin/layout/sidebar/_menuItem", args={
                  active       = ReFindNoCase( "mynewfeature$", event.getCurrentHandler() )
                , title        = event.translateResource( uri="mynewfeature.menu.title" )
                , link         = event.buildAdminLink( linkTo="mynewfeature" )
                , icon         = "fa-world-domination"
                , subMenuItems = subMenuItems
            } )#
        </cfoutput>
    </cfif>

.. note:: 
    
    In order for the calls to :code:`hasCmsPermission()` and :code:`translateResource()` to do anything useful, you will need to have setup the necessary permission keys (see :doc:`permissioning`) and resource bundle keys (see :doc:`i18n`).

Remove an existing item
-----------------------

In your site or extension's :code:`Config.cfc` file:

.. code-block:: java

    // ...

    // delete the site tree menu item, for example:
    settings.adminSideBarItems.delete( "sitetree" );

    // ...