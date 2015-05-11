<cfcomponent output="false" hint="I am a base Handler for all admin handlers. All admin handlers should extend me">
	<cfproperty name="adminDefaultEvent" inject="coldbox:setting:adminDefaultEvent" />

	<cffunction name="preHandler" access="public" returntype="void" output="false">
		<cfargument name="event"          type="any"    required="true" />
		<cfargument name="action"         type="string" required="true" />
		<cfargument name="eventArguments" type="struct" required="true" />

		<cfscript>
			_checkLogin( event );

			event.setLayout( "admin" );
			event.setLanguage( "" );
			event.includeData( {
				  ajaxEndpoint = event.buildAdminLink( linkTo="ajaxProxy" )
				, adminBaseUrl = event.getAdminPath()
			} );
			event.includeData( event.getCollection() );

			event.addAdminBreadCrumb(
				  title = translateResource( "cms:home.title" )
				, link  = event.buildAdminLink( linkTo=adminDefaultEvent )
			);
		</cfscript>
	</cffunction>


<!--- private helpers --->
	<cffunction name="_checkLogin" access="private" returntype="void" output="false">
		<cfargument name="event"          type="any"    required="true" />

		<cfscript>
			var loginExcempt = event.getCurrentEvent() contains 'admin.login' or event.getCurrentEvent() contains 'admin.ajaxProxy'; // ajaxProxy does its own login handling...
			var postLoginUrl = "";

			if ( not loginExcempt and not event.isAdminUser() ) {
				if ( event.isActionRequest() ) {
					if ( Len( Trim( cgi.http_referer ) ) ) {
						postLoginUrl = cgi.http_referer;
						if ( event.getHttpMethod() eq "POST" ) {
							getModel( "sessionService" ).setVar( "_unsavedFormData", Duplicate( form ) );
							getPlugin( "MessageBox" ).warn( translateResource( uri="cms:loggedout.saveddata.warning" ) );
						} else {
							getPlugin( "MessageBox" ).warn( translateResource( uri="cms:loggedout.noactiontaken.warning" ) );
						}
					} else {
						postLoginUrl = event.buildAdminLink( linkTo=adminDefaultEvent );
					}

				} else {
					postLoginUrl = event.getCurrentUrl();
				}

				setNextEvent( url=event.buildAdminLink( "login" ), persistStruct={ postLoginUrl = postLoginUrl } );
			}
		</cfscript>
	</cffunction>

</cfcomponent>