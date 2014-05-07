<cfcomponent output="false" extends="preside.system.base.AdminHandler">

	<cffunction name="index" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			if ( not event.isAdminUser() ) {
				event.renderData( type="json", data={ success=false, error=translateResource( "cms:ajax.access.denied.error" ) }, statusCode=403 );
			} else {
				var action = event.getValue( name="action", defaultValue="", statusCode=403 );
				if ( Len( Trim( action ) ) ) {
					event.noLayout();
					try {
						runEvent( "admin." & action );
					} catch( "HandlerService.EventHandlerNotRegisteredException" e ) {
						event.renderData( type="json", data={ success=false, error="Action, [#action#], is not a valid handler action" }, statusCode=500 );
					}
				} else {
					event.renderData( type="json", data={ success=false, error="You must supply an 'action' parameter to the Ajax Proxy" }, statusCode=500 );
				}
			}
		</cfscript>
	</cffunction>

</cfcomponent>