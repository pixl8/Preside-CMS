<cfcomponent output="false" hint="I am a base Handler for all admin handlers. All admin handlers should extend me">

	<cfproperty name="applicationsService" inject="applicationsService" />

	<cffunction name="preHandler" access="public" returntype="void" output="false">
		<cfargument name="event"          type="any"    required="true" />
		<cfargument name="action"         type="string" required="true" />
		<cfargument name="eventArguments" type="struct" required="true" />

		<cfscript>
			_checkLogin( event );
			var activeApplication = applicationsService.getActiveApplication( event.getCurrentEvent() );

			event.setLayout( applicationsService.getLayout( activeApplication ) );
			event.setLanguage( "" );
			event.includeData( {
				  ajaxEndpoint = event.buildAdminLink( linkTo="ajaxProxy" )
				, adminBaseUrl = event.getAdminPath()
			} );
			event.includeData( event.getCollection() );

			event.addAdminBreadCrumb(
				  title = translateResource( "cms:home.title" )
				, link  = event.buildLink( linkTo=applicationsService.getDefaultEvent( activeApplication ) )
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
							getPlugin( "sessionStorage" ).setVar( "_unsavedFormData", Duplicate( form ) );
							getPlugin( "MessageBox" ).warn( translateResource( uri="cms:loggedout.saveddata.warning" ) );
						} else {
							getPlugin( "MessageBox" ).warn( translateResource( uri="cms:loggedout.noactiontaken.warning" ) );
						}
					} else {
						postLoginUrl = event.buildAdminLink( linkTo=applicationsService.getDefaultEvent() );
					}

				} else {
					postLoginUrl = event.getCurrentUrl();
				}

				setNextEvent( url=event.buildAdminLink( "login" ), persistStruct={ postLoginUrl = postLoginUrl } );
			}
		</cfscript>
	</cffunction>

</cfcomponent>