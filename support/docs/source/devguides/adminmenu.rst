Modifying the administrator left hand menu
==========================================

Overview
########

You may find yourself wanting to change the left hand menu of the PresideCMS administrator, either to add new main navigational sections, take existing ones away or to modify their order and PresideCMS provides a simple mechanism for doing so.

Each top level item of the menu is stored in an array that is set in :code:`settings.adminSideBarItems` in :code:`Config.cfc`, The core implementation looks like this:

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

Each side bar item is then implemented as a view that lives under a :code:`/views/admin/layout/sidebar/` folder. 

For example, for the 'sitetree' item, there exists a view at :code:`/views/admin/layout/sidebar/sitetree.cfm` that looks like this:

.. code-block:: cfm

    <cfif hasCmsPermission( "sitetree.navigate" )>
        <cfoutput>
            <li<cfif listLast( event.getCurrentHandler(), ".") eq "sitetree"> class="active"</cfif>>
                <a href="#event.buildAdminLink( linkTo="sitetree" )#" data-goto-key="s">
                    <i class="fa fa-sitemap"></i>
                    <span class="menu-text">#translateResource( 'cms:sitetree' )#</span>
                </a>
            </li>
        </cfoutput>
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

Next, create the view for the side bar item:

.. code-block:: cfm

    <cfif hasCmsPermission( "mynewfeature.access" )>
        <cfoutput>
            <li<cfif listLast( event.getCurrentHandler(), ".") eq "mynewfeature"> class="active"</cfif>>
                <a href="#event.buildAdminLink( linkTo="mynewfeature" )#">
                    <i class="fa fa-cool"></i>
                    <span class="menu-text">#translateResource( 'cms:mynewfeature' )#</span>
                </a>
            </li>
        </cfoutput>
    </cfif>