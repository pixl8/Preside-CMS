Custom error pages
==================

Overview
########

PresideCMS provides a simple mechanism for creating custom 404 and 500 error pages while providing the flexibility to allow you to implement more complex systems should you need it.


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
