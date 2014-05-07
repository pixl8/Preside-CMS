<cfcomponent displayname="Logger" hint="Wrapper for multiple loggers" output="false" extends="_baseLogger">

<!--- constructor --->
	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="loggers" type="array" required="true" />

		<cfscript>
			super.init( argumentCollection = arguments );

			_setLoggers( arguments.loggers );

			return this;
		</cfscript>
	</cffunction>

<!--- private methods --->
	<cffunction name="_log" access="private" returntype="void" output="false">
		<cfargument name="type" type="string" required="true">
		<cfargument name="text" type="string" required="true">

		<cfscript>
			var loggers = _getLoggers();
			var i       = 1;

			for( i=1; i lte ArrayLen( loggers ); i=i+1 ) {
				switch( arguments.type ) {
					case "error":
						loggers[i].error( arguments.text );
					break;
					case "warning":
						loggers[i].warning( arguments.text );
					break;
					case "information":
						loggers[i].information( arguments.text );
					break;
					case "debug":
						loggers[i].debug( arguments.text );
					break;
				}
			}
		</cfscript>
	</cffunction>


<!--- getters and setters --->
	<cffunction name="_getLoggers" access="private" returntype="array" output="false">
		<cfreturn _loggers>
	</cffunction>
	<cffunction name="_setLoggers" access="private" returntype="void" output="false">
		<cfargument name="loggers" type="array" required="true" />
		<cfset _loggers = arguments.loggers />
	</cffunction>
</cfcomponent>