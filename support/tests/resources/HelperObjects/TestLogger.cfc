<cfcomponent displayname="Logger" hint="Provides common logging functionality" output="false">

<!--- constructor --->
	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="logLevel" type="string"  required="true" />

		<cfscript>
			_setLogLevel( LCase( arguments.logLevel ) );
			_setRequestKey( "testLog_" & CreateUUId() );

			return this;
		</cfscript>
	</cffunction>

<!--- public methods --->
	<cffunction name="getLogs" access="public" returntype="array" output="false">
		<cfscript>
			var logKey = _getRequestKey();
			var log = "";

			if ( not StructKeyExists( request, logKey ) ) {
				request[ logKey ] = [];
			}

			log = Duplicate( request[ logKey ] );

			request[ logKey ] = [];

			return log;
		</cfscript>
	</cffunction>

	<cffunction name="error" access="public" returntype="void" output="false">
		<cfargument name="text"  type="string" required="false" default="" />
		<cfargument name="error" type="struct" required="false" />

	   <cfscript>
			if ( StructKeyExists( arguments, "error" )) {
				arguments.text = _formatErrorForLog( arguments.error );
			}
			_log(
				  type    = "Error"
				, text    = arguments.text
			);
		</cfscript>
	</cffunction>

	<cffunction name="warning" access="public" returntype="void" output="false">
		<cfargument name="text" type="string" required="true" />

		<cfscript>
			if ( Find( _getLogLevel(), "warning,information,debug" ) ){
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
			if ( Find( _getLogLevel(), "information,debug" ) ){
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
			if ( Find( _getLogLevel(), "debug" ) ){
				_log(
					  type    = "debug"
					, text    = arguments.text
				);
			}
		</cfscript>
	</cffunction>


<!--- private function --->
	<cffunction name="_log" access="private" returntype="void" output="false">
		<cfargument name="type" type="string" required="true" />
		<cfargument name="text" type="string" required="true" />

		<cfscript>
			var logKey = _getRequestKey();

			if ( not StructKeyExists( request, logKey ) ) {
				request[ logKey ] = [];
			}

			ArrayAppend( request[ logKey ], "#arguments.type#: " & arguments.text );
		</cfscript>
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

	<cffunction name="_getRequestKey" access="private" returntype="string" output="false">
		<cfreturn _requestKey>
	</cffunction>
	<cffunction name="_setRequestKey" access="private" returntype="void" output="false">
		<cfargument name="requestKey" type="string" required="true" />
		<cfset _requestKey = arguments.requestKey />
	</cffunction>

	<cffunction name="_getLogLevel" access="private" returntype="string" output="false">
		<cfreturn _LogLevel />
	</cffunction>
	<cffunction name="_setLogLevel" access="private" returntype="void" output="false">
		<cfargument name="LogLevel" type="string" required="true" />
		<cfset _LogLevel = arguments.LogLevel />
	</cffunction>
</cfcomponent>