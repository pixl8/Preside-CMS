Sitetree Navigation Menus
=========================

Overview
########

A common task for CMS driven websites is to build navigation menus based on the site tree. PresideCMS provides two extendable viewlets (see :doc:`viewlets`) to aid in rendering such menus with the minimum of fuss; :code:`core.navigation.mainNavigation` and :code:`core.navigation.subNavigation`.

Main navigation
###############

The purpose of the main navigation viewlet is to render the menu that normally appears at the top of a website and that is usually either one, two or three levels deep. For example:

.. code-block:: cfm

    <nav role="navigation">
        <ul class="nav navbar-nav">
            <li class="hiddex-sm home-nav"><a href="/"><span class="fa fa-home"></span></a></li>
            
            #renderViewlet( event="core.navigation.mainNavigation", args={ depth=2 } )#
        </ul>
    </nav>

This would result in output that looked something like this:

.. code-block:: html

    <nav class="site-navigation" role="navigation">
        <ul class="nav navbar-nav">
            <li class="hiddex-sm home-nav"><a href="/"><span class="fa fa-home"></span></a></li>

            <!-- start of "core.navigation.mainNavigation" -->
            <li class="active">
                <a href="/news.html">News</a>
            </li>
            <li class="dropdown">
                <a href="/about.html">About us</a>
                <ul class="dropdown-menu" role="menu">
                    <li><a href="/about/team.html">Our team</a></li>
                    <li><a href="/about/offices.html">Our offices</a></li>
                    <li><a href="/about/ethos.html">Our ethos</a></li>
                </ul>
            </li>
            <li>
                <a href="/contact.html">Contact</a>
            </li>
            <!-- end of "core.navigation.mainNavigation" -->
        </ul>
    </nav>

.. note::

    Notice how the core implementation does not render the outer :code:`<ul>` element for you. This allows you to build navigation items either side of the automatically generated navigation such as login links and other application driven navigation.

Viewlet options
---------------

You can pass the following arguments to the viewlet through the :code:`args` structure:

================ =============================================================================================================================================
Name             Description
================ =============================================================================================================================================
:code:`rootPage` ID of the page who's children make up the top level of the menu. This defaults to the site's homepage.
:code:`depth`    Number of nested dropdown levels to drill into. Default is 1, i.e. just render the immediate children of the root page and have no drop downs
================ =============================================================================================================================================

Overriding the view
-------------------

You might find yourself in a position where the HTML markup provided by the core implementation does not suit your needs. You can override this markup by providing a view at :code:`/views/core/navigaton/mainNavigation.cfm`. The view will be passed a single argument, :code:`args.menuItems`, which is an array of structs who's structure looks like this:

.. code-block:: json

    [
        {
            "id"       : "F9923DE1-9B2D-4544-A4E7F8E198888211",
            "title"    : "News",
            "active"   : true,
            "children" : []
        },
        {
            "id"       : "F9923DE1-9B2D-4544-A4E7F8E198888A6F",
            "title"    : "About us",
            "active"   : false,
            "children" : [
                {
                    "id"       : "F9923DE1-9B2D-4544-A4E7F8E198888000",
                    "title"    : "Our team",
                    "active"   : false,
                    "children" : []      
                },
                {
                    "id"       : "F9923DE1-9B2D-4544-A4E7F8E198888FF8",
                    "title"    : "Our offices",
                    "active"   : false,
                    "children" : []      
                },
                {
                    "id"       : "F9923DE1-9B2D-4544-A4E7F8E1988887FE",
                    "title"    : "Our ethos",
                    "active"   : false,
                    "children" : []      
                }
            ]
        },
        {
            "id"       : "F9923DE1-9B2D-4544-A4E7F8E19888834A",
            "title"    : "COntact us",
            "active"   : false,
            "children" : []
        }
    ]

This is what the core view implementation looks like:

.. code-block:: cfm

    <cfoutput>
        <cfloop array="#( args.menuItems ?: [] )#" index="i" item="item">
            <li class="<cfif item.active>active </cfif><cfif item.children.len()>dropdown</cfif>">
                <a href="#event.buildLink( page=item.id )#">#item.title#</a>
                <cfif item.children.len()>
                    <ul class="dropdown-menu" role="menu">
                        <!--- NOTE the recursion here --->
                        #renderView( view='/core/navigation/mainNavigation', args={ menuItems=item.children } )#
                    </ul>
                </cfif>
            </li>
        </cfloop>
    </cfoutput>