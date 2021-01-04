<cffunction name="setLogMessage" access="public" returntype="void" output="false">
	<cfargument name="message"  type="string" required="true" />
	<cfargument name="logger"   type="any"    required="false" />
	<cfargument name="severity" type="string" required="false" default="info" />

	<cfscript>
		if ( !isNull( arguments.logger ) ) {
			if ( arguments.logger[ "can#arguments.severity#" ]() ) {
				arguments.logger[ arguments.severity ]( arguments.message );
			}
		}
	</cfscript>
</cffunction>
