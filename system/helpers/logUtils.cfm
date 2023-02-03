<cffunction name="logMessage" access="public" returntype="void" output="false">
	<cfargument name="logger"   type="any"    required="false" />
	<cfargument name="severity" type="string" required="true" />
	<cfargument name="message"  type="string" required="true" />

	<cfscript>
		if ( !IsNull( arguments.logger ) ) {
			if ( arguments.logger[ "can#arguments.severity#" ]() ) {
				arguments.logger[ arguments.severity ]( arguments.message );
			}
		}
	</cfscript>
</cffunction>
