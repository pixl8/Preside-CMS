<cfcomponent displayname="Logger" hint="Provides common logging functionality" output="false">

	<cfscript>
		variables.loglevels = {
			  debug       = 0
			, information = 1
			, warning     = 2
			, error       = 3
		};
	</cfscript>

<!--- constructor --->
	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="logLevel" type="string"  required="true" />

		<cfscript>
			_setLogLevel( LCase( arguments.logLevel ) );

			return this;
		</cfscript>
	</cffunction>

<!--- public methods --->
	<cffunction name="error" access="public" returntype="void" output="false">
		<cfargument name="text"  type="string" required="false" default="" />
		<cfargument name="error" type="struct" required="false" />

	   <cfscript>
			if ( _isLogLevelActive( "error" ) ){
				if ( StructKeyExists( arguments, "error" )) {
					arguments.text = _formatErrorForLog( arguments.error );
				}
				_log(
					  type    = "Error"
					, text    = arguments.text
				);
			}
		</cfscript>
	</cffunction>

	<cffunction name="warning" access="public" returntype="void" output="false">
		<cfargument name="text" type="string" required="true" />

		<cfscript>
			if ( _isLogLevelActive( "warning" ) ){
				_log(
					  type = "Warning"
					, text = arguments.text
				);
			}
		</cfscript>
	</cffunction>

	<cffunction name="information" access="public" returntype="void" output="false">
		<cfargument name="text" type="string" required="true" />

		<cfscript>
			if ( _isLogLevelActive( "information" ) ){
				_log(
					  type    = "Information"
					, text    = arguments.text
				);
			}
		</cfscript>
	</cffunction>

	<cffunction name="debug" access="public" returntype="void" output="false">
		<cfargument name="text" type="string" required="true" />

		<cfscript>
			if ( _isLogLevelActive( "debug" ) ){
				_log(
					  type    = "debug"
					, text    = arguments.text
				);
			}
		</cfscript>
	</cffunction>


<!--- private function --->
	<cffunction name="_log" access="private" returntype="void" output="false">
		<cfthrow type="baseLogger.missingImplementation" message="Your logger must implement the _log() method. It takes two arguments, 'type' and 'message'." />
	</cffunction>

	<cffunction name="_formatErrorForLog" access="private" returntype="string" output="false">
		<cfargument name="error" type="struct" required="true" />

		<cfparam name="arguments.error.type"        default="" />
		<cfparam name="arguments.error.template"    default="" />
		<cfparam name="arguments.error.message"     default="" />
		<cfparam name="arguments.error.detail"      default="" />
		<cfparam name="arguments.error.diagnostics" default="" />

		<cfreturn "Exception error --
		            Exception type: #arguments.error.type#
		            Template: #arguments.error.template#,
		            Message: #arguments.error.message#,
		            Detail: #arguments.error.detail#,
		            Diagnostics: #arguments.error.diagnostics#" />

	</cffunction>

	<cffunction name="_isLogLevelActive" access="private" returntype="boolean" output="false">
		<cfargument name="logLevel" type="string" required="true" />

		<cfscript>
			if ( StructKeyExists( variables.logLevels, arguments.logLevel ) ) {
				return variables.logLevels[ arguments.logLevel ] gte _getLogLevel();
			}

			return false;
		</cfscript>
	</cffunction>

	<cffunction name="_getLogLevel" access="private" returntype="numeric" output="false">
		<cfreturn _logLevel />
	</cffunction>
	<cffunction name="_setLogLevel" access="private" returntype="void" output="false">
		<cfargument name="LogLevel" type="string" required="true" />
		<cfscript>
			if ( StructKeyExists( variables.logLevels, arguments.logLevel ) ) {
				_logLevel = logLevels[ arguments.logLevel ];
			} else {
				_logLevel = 0;
			}
		</cfscript>
	</cffunction>
</cfcomponent>