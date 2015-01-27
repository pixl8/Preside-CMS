Routing
=======

.. contents:: :local:

Overview
########

Routing is the term used to describe how a URL gets mapped to actions and input variables in your application. In PresideCMS, the action will be a `Coldbox event handler`_ and the input variables will appear in your request context.

We use Coldbox's own routing system along with a PresideCMS addition for handling dynamic routes. When creating your own custom routes, you are free to use either system.

URLs can be built with :code:`event.buildLink()`. Different routing URLs will be generated depending on the arguments passed to the :code:`buildLink()` function.


Creating custom routes
######################

To create custom routes for your site, you must create a :code:`Routes.cfm` file in your :code:`/application/config/` directory. In this file, you can create regular `ColdBox routes`_ as well as PresideCMS routes. The following routes.cfm file registers a couple of PresideCMS route handlers:

.. code-block:: js

    addRouteHandler( getModel( "myCustomRouteHandler" ) );
    addRouteHandler( CreateObject( "app.routeHandlers.anotherCustomRouteHandler" ).init() );

PresideCMS Route Handlers
-------------------------

A PresideCMS Route Handler is any CFC that implements a simple interface to handle routing. The interface looks like this:

.. code-block:: js

    interface {
        // match(): return true if the incoming URL path should be handled by this route handler
        public boolean function match( required string path, required any event ) output=false {}

        // translate(): take an incoming URL and translate it - use the ColdBox event object to set variables and the current event
        public void    function translate( required string path, required any event ) output=false {}

        // reverseMatch(): return true if the incomeing set of arguments passed to buildLink() should be handled by this route handler
        public boolean function reverseMatch( required struct buildArgs ) output=false {}

        // build(): take incoming buildLink() arguments and return a URL string
        public string  function build( required struct buildArgs ) output=false {}
    }

An example route handler, that deals with custom URLs for a "My Profile" area of a website, might look like this:

.. code-block:: js

    component implements="preside.system.routeHandlers.iRouteHandler" output=false {

        public boolean function match( required string path, required any event ) output=false {
            return ReFindNoCase( "^/my-profile/", arguments.path );
        }

        public void function translate( required string path, required any event ) output=false {
            var coldboxEventName = ReReplace( arguments.path, "^/my-profile/", "myprofilemodule:myprofile/" );

            coldboxEventName = ListChangeDelims( coldboxEventName, ".", "/" );

            if ( ListLen( coldboxEventName, "." ) lt 2 ) {
                coldboxEventName = coldboxEventName & "." & "index";
            }

            event.setValue( "event", coldboxEventName );
        }

        public boolean function reverseMatch( required struct buildArgs ) output=false {
            return Len( Trim( buildArgs.linkTo ?: "" ) ) and ListFirst( buildArgs.linkTo, "." ) eq "myprofilemodule:myprofile";
        }

        public string function build( required struct buildArgs ) output=false {
            var link = "/my-profile/#ListChangeDelims( ListRest( buildArgs.linkTo, "." ), "/", "." )#/";

            if ( Len( Trim( buildArgs.queryString ?: "" ) ) ) {
                link &= "?" & buildArgs.queryString;
            }

            return link;
        }
    }


URL Rewriting
#############

In order for the core routes to work, URL rewrites need to be in place. PresideCMS server distributions ship with the `Tuckey URL rewrite filter`_ installed and expect to find a :code:`urlrewrite.xml` file in your webroot. The PresideCMS site skeleton builder creates one of these for you with the following rules which you are then free to modify and/or augment:

.. code-block:: xml

    <?xml version="1.0" encoding="utf-8"?>
    <!DOCTYPE urlrewrite PUBLIC "-//tuckey.org//DTD UrlRewrite 4.0//EN" "http://www.tuckey.org/res/dtds/urlrewrite4.0.dtd">
    <urlrewrite>
        <rule>
            <note>
                All request to system static assets that live under /preside/system/assets
                should go through Railo and will be rewritten to /index.cfm
            </note>
            <from>^/preside/system/assets/.*$</from>
            <to>%{context-path}/index.cfm</to>
        </rule>

        <rule>
            <note>
                All request to *.html or ending in / will be rewritten to /index.cfm
            </note>
            <from>^(/((.*?)(\.html|/))?)$</from>
            <to>%{context-path}/index.cfm</to>
        </rule>

        <rule>
            <note>
                Disable Railo Context except for local requests
            </note>
            <condition type="remote-addr" operator="notequal">^(127\.0\.0\.1|0:0:0:0:0:0:0:1)$</condition>
            <from>^/railo-context/.*$</from>
            <set type="status">404</set>
            <to>null</to>
        </rule>

         <rule>
            <note>
                All the following requests should not be allowed and should return with a 404
                We block any request to:

                * the application folder (where all the logic and views for your site lives)
                * the uploads folder (should be configured to be somewhere else anyways)
                * this url rewrite file!
            </note>
            <from>^/(application/|uploads/|urlrewrite\.xml\b)</from>
            <set type="status">404</set>
            <to>null</to>
        </rule>
    </urlrewrite>

Out-of-the-box routes
#####################

Site tree pages
---------------

Any URL that ends with :code:`.html` followed by an optional query string, will be routed as a site tree page URL. The "directories" and "filename" will correspond to the slugs of the pages in your tree. For example:

    :code:`/about-us/meet-the-team/alex-skinner.html?showComments=true`

will be routed to:

.. code-block:: js

    Coldbox event : core.SiteTreePageRequestHandler
    Coldbox RC    : { showComments : true }
    Coldbox PRC   : { slug : "about-us.meet-the-team.alex-skinner" }

and map to the site tree page:

.. code-block:: text

    /about-us
        /meet-the-team
            alex-skinner

.. tip::

    You can build a link to a site tree page with :code:`event.buildLink( page=idOfThePage )`

PresideCMS Admin pages and actions
----------------------------------

Any URL that begins with :code:`/(adminPath)` and ends in a forward slash followed by an optional query string, will be routed as a PresideCMS admin request. Directory nodes in the URL will be translated to the ColdBox event.

.. note::

    Your admin path can be configured in your site's :doc:`Config.cfc <configcfc>` file with the :code:`settings.preside_admin_path` setting. The setting defaults to "preside_admin".

For example, assuming that :code:`settings.preside_admin_path` has been set to "acme_cmsarea", the URL :code:`/acme_cmsarea/sitetree/editPage/?id=F4554E4C-9347-4F7E-B5F862595BFC9EBF` will be routed to:

.. code-block:: js

    Coldbox event : admin.sitetree.editPage
    Coldbox RC    : { id : "F4554E4C-9347-4F7E-B5F862595BFC9EBF" }

.. tip::

    You can build a link to an admin event with :code:`event.buildAdminLink( linkTo="sitetree.editPage", queryString="id=#pageId#" )` or :code:`event.buildLink( linkTo="admin.sitetree.editPage", queryString="id=#pageId#" )`

Asset manager assets
--------------------

Assets stored in the asset manager are served through the application. Any URL that starts with :code:`/asset` and ends with a trailing slash will be routed to the asset manager download action. URLs take the form: :code:`/asset/(asset ID)/` or :code:`/asset/(asset ID)/(ID or name of derivative)/`. So the URL, :code:`/asset/F4554E4C-9347-4F7E-B5F862595BFC9EBF/`, is routed to:

.. code-block:: js

    Coldbox event : core.assetDownload
    Coldbox RC    : { assetId : "F4554E4C-9347-4F7E-B5F862595BFC9EBF" }

and :code:`/asset/F4554E4C-9347-4F7E-B5F862595BFC9EBF/headerImage/` becomes:

.. code-block:: js

    Coldbox event : core.assetDownload
    Coldbox RC    : { assetId : "F4554E4C-9347-4F7E-B5F862595BFC9EBF", derivativeId : "headerImage" }

.. tip::

    You can build a link to an asset with :code:`event.buildAdminLink( assetId=myAssetId )` or :code:`event.buildLink( assetId=myAssetId, derivative=derivativeId )`


.. _Coldbox event handler: http://wiki.coldbox.org/wiki/EventHandlers.cfm
.. _Tuckey URL rewrite filter: http://tuckey.org/urlrewrite/
.. _Coldbox routes: http://wiki.coldbox.org/wiki/URLMappings.cfm