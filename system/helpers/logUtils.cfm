<cffunction name="setLogMessage" access="public" returntype="void" output="false">
	<cfargument name="logger"   type="any"    required="true" />
	<cfargument name="message"  type="string" required="true" />
	<cfargument name="severity" type="string" required="false" default="info" />

	<cfscript>
		if ( arguments.logger[ "can#severity#" ]() ) {
			arguments.logger[ severity ]( arguments.message );
		}
	</cfscript>
</cffunction>
