<cfcomponent extends="preside.system.base.AdminHandler" output="false">

	<cfproperty name="adminLoginService"    inject="adminLoginService" />
	<cfproperty name="sessionService"       inject="sessionService"       />
	<cfproperty name="adminDefaultEvent"    inject="coldbox:setting:adminDefaultEvent" />
	<cfproperty name="messageBox"           inject="coldbox:plugin:messageBox" />

	<cffunction name="preHandler" access="public" returntype="void" output="false">
		<cfargument name="event"          type="any"    required="true" />
		<cfargument name="action"         type="string" required="true" />
		<cfargument name="eventArguments" type="struct" required="true" />

		<cfscript>
			super.preHandler( argumentCollection = arguments );

			event.setLayout( 'adminLogin' );
		</cfscript>
	</cffunction>

	<cffunction name="index" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			if ( event.isAdminUser() ){
				setNextEvent( url=event.buildAdminLink( linkto=adminDefaultEvent ) );
			}
		</cfscript>
	</cffunction>

	<cffunction name="login" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var user         = "";
			var postLoginUrl = event.getValue( name="postLoginUrl", defaultValue="" );
			var unsavedData  = sessionService.getVar( "_unsavedFormData", {} );
			var loggedIn     = adminLoginService.logIn(
				  loginId  = event.getValue( name="loginId" , defaultValue="" )
				, password = event.getValue( name="password", defaultValue="" )
			);

			if ( loggedIn ) {
				if ( !event.hasAdminPermission( "cms.login" ) ) {
					adminLoginService.logout();
					messageBox.error( translateResource( uri="cms:login.no.login.rights.error" ) );
					setNextEvent( url=event.buildAdminLink( linkto="login", persist="postLoginUrl" ) );
				}
				user = event.getAdminUserDetails();
				event.audit(
					  detail   = "[#user.knownAs#] has logged in"
					, source   = "login"
					, action   = "login_success"
					, type     = "user"
					, instance = user.userId
				);

				if ( Len( Trim( postLoginUrl ) ) ) {
					sessionService.deleteVar( "_unsavedFormData", {} );
					setNextEvent( url=_cleanPostLoginUrl( postLoginUrl ), persistStruct=unsavedData );
				} else {
					setNextEvent( url=event.buildAdminLink( linkto=adminDefaultEvent ) );
				}
			} else {
				setNextEvent( url=event.buildAdminLink( linkto="login", persist="postLoginUrl" ) );
			}
		</cfscript>
	</cffunction>

	<cffunction name="logout" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var user        = "";

			if ( event.isAdminUser() ) {
				user = event.getAdminUserDetails();

				event.audit(
					  detail   = "[#user.knownAs#] has logged out"
					, source   = "logout"
					, action   = "logout_success"
					, type     = "user"
					, instance = user.userId
				);

				adminLoginService.logout();
			}

			if ( ( rc.redirect ?: "" ) == "referer" ) {
				setNextEvent( url=cgi.http_referer );
			}

			setNextEvent( url=event.buildAdminLink( linkto="login" ) );
		</cfscript>
	</cffunction>

<!--- private helpers --->
	<cffunction name="_cleanPostLoginUrl" access="private" returntype="string" output="false">
		<cfargument name="postLoginUrl" type="string" required="true" />

		<cfscript>
			var cleaned = Trim( arguments.postLoginUrl );

			cleaned = ReReplace( cleaned, "^(https?://.*?)//", "\1/" );

			return cleaned;
		</cfscript>
	</cffunction>
</cfcomponent>