Custom error pages
==================

.. contents:: :local:

Overview
########

PresideCMS provides a simple mechanism for creating custom 401, 404 and 500 error pages while providing the flexibility to allow you to implement more complex systems should you need it.


404 Not found pages
###################

Creating a 404 template
-----------------------

The 404 template is implemented as a Preside Viewlet (see :doc:`viewlets`) and a core implementation already exists. The name of the viewlet is configured in your application's Config.cfc with the :code:`notFoundViewlet` setting. The default is "errors.notFound":

.. code-block:: java

    // /application/config/Config.cfc
    component extends="preside.system.config.Config" output=false {

        public void function configure() output=false {
            super.configure();

            // other settings...
            settings.notFoundViewlet = "errors.notFound";
        }
    }

For simple cases, you will only need to override the :code:`/errors/notFound` view by creating one in your application's view folder, e.g.

.. code-block:: cfm

    <!--- /application/views/errors/notFound.cfm --->
    <h1>These are not the droids you are looking for</h1>
    <p> Some pithy remark.</p>

Implementing handler logic
~~~~~~~~~~~~~~~~~~~~~~~~~~

If you wish to perform some handler logic for your 404 template, you can simply create the Errors.cfc handler file and implement the "notFound" action. For example:

.. code-block:: java

    // /application/handlers/Errors.cfc
    component output=false {

        private string function notFound( event, rc, prc, args={} ) output=false {
            event.setHTTPHeader( statusCode="404" );
            event.setHTTPHeader( name="X-Robots-Tag", value="noindex" );

            return renderView( view="/errors/notFound", args=args );
        }
    }

Defining a layout template
~~~~~~~~~~~~~~~~~~~~~~~~~~

The default layout template for the 404 is your site's default layout, i.e. "Main" (/application/layouts/Main.cfm). If you wish to configure a different default layout template for your 404 template, you can do so with the :code:`notFoundLayout` configuration option, i.e.

.. code-block:: java

    // /application/config/Config.cfc
    component extends="preside.system.config.Config" output=false {

        public void function configure() output=false {
            super.configure();

            // other settings...

            settings.notFoundLayout  = "404Layout";
            settings.notFoundViewlet = "errors.my404Viewlet";
        }
    }

You can also programatically set the layout for your 404 template in your handler (you may wish to dynamically pick the layout depending on a number of variables):

.. code-block:: java

    // /application/handlers/Errors.cfc
    component output=false {

        private string function notFound( event, rc, prc, args={} ) output=false {
            event.setHTTPHeader( statusCode="404" );
            event.setHTTPHeader( name="X-Robots-Tag", value="noindex" );
            event.setLayout( "404Layout" );

            return renderView( view="/errors/notFound", args=args );
        }
    }



Programatically responding with a 404
-------------------------------------

If you ever need to programatically respond with a 404 status, you can use the :code:`event.notFound()` method to do so. This method will ensure that the 404 statuscode header is set and will render your configured 404 template for you. For example:

.. code-block:: java

    // someHandler.cfc
    component output=false {

        public void function index( event, rc, prc ) output=false {
            prc.record = getModel( "someService" ).getRecord( rc.id ?: "" );

            if ( !prc.record.recordCount ) {
                event.notFound();
            }

            // .. carry on processing the page
        }
    }

Direct access to the 404 template
---------------------------------

The 404 template can be directly accessed by visiting /404.html. This is achieved through a custom route dedicated to error pages (see :doc:`routing`).

This is particular useful for rendering the 404 template in cases where PresideCMS is not producing the 404. For example, you may be serving static assets directly through Tomcat and want to see the custom 404 template when one of these assets is missing. To do this, you would edit your :code:`${catalina_home}/config/web.xml` file to define a rewrite URL for 404s:

.. code-block:: xml
    
    <!-- ... -->

            <welcome-file-list>
            <welcome-file>index.cfm</welcome-file>
        </welcome-file-list>

        <error-page>
            <error-code>404</error-code>
            <location>/404.html</location>
        </error-page>

    </web-app>

Another example is producing 404 responses for secured areas of the application. In PresideCMS's default urlrewrite.xml file (that works with Tuckey URL Rewrite), we block access to files such as Application.cfc by responding with a 404:

.. code-block:: xml
    
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

.. _custom-error-pages-401:

401 Access denied pages
#######################

Access denied pages can be created and used in exactly the same way as 404 pages, with a few minor differences. The page can be invoked with :code:`event.accessDenied( reason=deniedReason )` and will be automatically invoked by the core access control system when a user attempts to access pages and assets to which they do not have permission.

.. hint::

    For a more in depth look at front end user permissioning and login, see :doc:`websiteusers`.

Creating a 401 template
-----------------------

The 401 template is implemented as a Preside Viewlet (see :doc:`viewlets`) and a core implementation already exists. The name of the viewlet is configured in your application's Config.cfc with the :code:`accessDeniedViewlet` setting. The default is "errors.accessDenied":

.. code-block:: java

    // /application/config/Config.cfc
    component extends="preside.system.config.Config" output=false {

        public void function configure() output=false {
            super.configure();

            // other settings...
            settings.accessDeniedViewlet = "errors.accessDenied";
        }
    }

The viewlet will be passed an :code:`args.reason` argument that will be either :code:`LOGIN_REQUIRED`, :code:`INSUFFICIENT_PRIVILEGES` or any other codes that you might make use of.

The core implementation sets the 401 header and then renders a different view, depending on the access denied reason:

.. code-block:: java

    // /preside/system/handlers/Errors.cfc
    component output=false {

        private string function accessDenied( event, rc, prc, args={} ) output=false {
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

For simple cases, you will only need to override the :code:`/errors/insufficientPrivileges` and/or :code:`/errors/loginRequired` view by creating them in your application's view folder, e.g.

.. code-block:: cfm

    <!--- /application/views/errors/insufficientPrivileges.cfm --->
    <h1>Name's not on the door, you ain't coming in</h1>
    <p> Some pithy remark.</p>

.. code-block:: cfm

    <!--- /application/views/errors/loginRequired.cfm --->
    #renderViewlet( event="login.loginPage", message="LOGIN_REQUIRED" )#

Implementing handler logic
~~~~~~~~~~~~~~~~~~~~~~~~~~

If you wish to perform some handler logic for your 401 template, you can simply create the Errors.cfc handler file and implement the "accessDenied" action. For example:

.. code-block:: java

    // /application/handlers/Errors.cfc
    component output=false {
        private string function accessDenied( event, rc, prc, args={} ) output=false {
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

Defining a layout template
~~~~~~~~~~~~~~~~~~~~~~~~~~

The default layout template for the 401 is your site's default layout, i.e. "Main" (/application/layouts/Main.cfm). If you wish to configure a different default layout template for your 401 template, you can do so with the :code:`accessDeniedLayout` configuration option, i.e.

.. code-block:: java

    // /application/config/Config.cfc
    component extends="preside.system.config.Config" output=false {

        public void function configure() output=false {
            super.configure();

            // other settings...

            settings.accessDeniedLayout  = "401Layout";
            settings.accessDeniedViewlet = "errors.my401Viewlet";
        }
    }

You can also programatically set the layout for your 401 template in your handler (you may wish to dynamically pick the layout depending on a number of variables):

.. code-block:: java

    // /application/handlers/Errors.cfc
    component output=false {
        private string function accessDenied( event, rc, prc, args={} ) output=false {
            event.setHTTPHeader( statusCode="401" );
            event.setHTTPHeader( name="X-Robots-Tag"    , value="noindex" );
            event.setHTTPHeader( name="WWW-Authenticate", value='Website realm="website"' ); // this header is required by the HTTP protocol when returning a 401 reponse

            event.setLayout( "myCustom401Layout" );

            // ... etc.
        }
    }

Programatically responding with a 401
-------------------------------------

If you ever need to programatically respond with a 401 access denied status, you can use the :code:`event.accessDenied( reason="MY_REASON" )` method to do so. This method will ensure that the 401 statuscode header is set and will render your configured 401 template for you. For example:

.. code-block:: java

    // someHandler.cfc
    component output=false {

        public void function reservePlace( event, rc, prc ) output=false {
            if ( !isLoggedIn() ) {
                event.accessDenied( reason="LOGIN_REQUIRED" );
            }
            if ( !hasWebsitePermission( "events.reserveplace" ) ) {
                event.accessDenied( reason="INSUFFICIENT_PRIVILEGES" );
            }

            // .. carry on processing the page
        }
    }

500 Error Pages
###############

The implementation of 500 error pages is more straight forward than the 40x templates and involves only creating a flat :code:`500.htm` file in your webroot. The reason behind this is that a server error may be caused by your site's layout code, or may even occur before PresideCMS code is called at all; in which case the code to render your error template will not be available.

If you do not create a :code:`500.htm` in your webroot, PresideCMS will use it's own default template for errors. This can be found at :code:`/preside/system/html/500.htm`.

Bypassing the error template
----------------------------

In your local development environment, you will want to be able see the details of errors, rather than view a simple error message. This can be achieved with the config setting, :code:`showErrors`:

.. code-block:: java

    // /application/config/Config.cfc
    component extends="preside.system.config.Config" output=false {

        public void function configure() output=false {
            super.configure();

            // other settings...

            settings.showErrors = true;
        }
    }

In most cases however, you will not need to configure this for your local environment. PresideCMS uses ColdBox's environment configuration (see :doc:`coldboxenvironments`) to configure a "local" environment that already has :code:`showErrors` set to **true** for you. If you wish to override that setting, you can do so by creating your own "local" environment function:

.. code-block:: java

    // /application/config/Config.cfc
    component extends="preside.system.config.Config" output=false {

        public void function configure() output=false {
            super.configure();

            // other settings...
        }

        public void function local() output=false {
            super.local();

            settings.showErrors = false;
        }
    }

.. note::

    PresideCMS's built-in local environment configuration will map URLs like "mysite.local", "local.mysite", "localhost" and "127.0.0.1" to the "local" environment.