<cfcomponent output="false" extends="_baseLogger">

<!--- constructor --->
	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="endpoint"  type="string" required="true" />
		<cfargument name="jobPrefix" type="string" required="false" default="" />
		<cfargument name="username"  type="string" required="true" />
		<cfargument name="apiKey"    type="string" required="true" />

		<cfscript>
			super.init( argumentCollection = arguments );

			_setEndpoint( arguments.endpoint );
			_setJobPrefix( arguments.jobPrefix );
			_setUsername( arguments.username );
			_setApiKey( arguments.apiKey );
			_setRequestKey( "jenkinsLog_" & CreateUUId() );

			return this;
		</cfscript>
	</cffunction>

<!--- public methods --->
	<cffunction name="pushToJenkins" access="public" returntype="void" output="false">
		<cfargument name="jobName"     type="string"  required="true" />
		<cfargument name="duration"    type="numeric" required="false" default="-1" hint="Duration, in milliseconds of the job run" />
		<cfargument name="displayName" type="string"  required="false" default="" />
		<cfargument name="description" type="string"  required="false" default="" />

		<cfscript>
			var log     = _getLogFromRequest();
			var payload = _craftPayload(
				  resultCode  = log.statusCode
				, text        = log.log
				, duration    = arguments.duration
				, displayName = arguments.displayName
				, description = arguments.description
			);

			_clearLog();

			_pushPayloadToJenkinsServerAsynchronously( arguments.jobName, payload );
		</cfscript>
	</cffunction>

<!--- private helpers --->
	<cffunction name="_log" access="private" returntype="void" output="false">
		<cfargument name="type" type="string" required="true" />
		<cfargument name="text" type="string" required="true" />

		<cfscript>
			var log = _getLogFromRequest();
			var message = DateFormat( Now(), 'yyyy-mm-dd ' ) & TimeFormat( Now(), 'HH:mm:ss ' ) & UCase( arguments.type ) & ": " & arguments.text;

			log.log = ListAppend( log.log, message, Chr(10) );

			if ( listFindNoCase( "error,warning", arguments.type ) ) {
				log.statusCode = 1;
			}
		</cfscript>
	</cffunction>

	<cffunction name="_craftPayload" access="private" returntype="string" output="false">
		<cfargument name="text"        type="string"  required="true" />
		<cfargument name="resultCode"  type="numeric" required="true" />
		<cfargument name="duration"    type="numeric" required="true" />
		<cfargument name="displayName" type="string"  required="true" />
		<cfargument name="description" type="string"  required="true" />

		<cfset var payload = "" />
		<cfsavecontent variable="payload"><cfoutput>
			<?xml version="1.0"?>
			<run>
				<log encoding="hexBinary">#_stringToHex( arguments.text )#</log>
				<result>#Round( arguments.resultCode )#</result>

				<cfif StructKeyExists( arguments, "duration" )>
					<duration>#Round( arguments.duration )#</duration>
				</cfif>
				<cfif StructKeyExists( arguments, "displayName" )>
					<displayName>#XmlFormat( Trim( arguments.displayName ) )#</displayName>
				</cfif>
				<cfif StructKeyExists( arguments, "description" )>
					<description>#XmlFormat( Trim( arguments.description ) )#</description>
				</cfif>
			</run>
		</cfoutput></cfsavecontent>

		<cfreturn Trim( payload ) />
	</cffunction>

	<cffunction name="_pushPayloadToJenkinsServerAsynchronously" access="private" returntype="void" output="false">
		<cfargument name="jobName" type="string" required="true" />
		<cfargument name="payload" type="string" required="true" />

		<cfset var endpoint = _getEndpoint() & "/job/" & _getJobPrefix() & UrlEncodedFormat( arguments.jobName ) & "/postBuildResult" />

		<cfthread name="#CreateUUId()#" payload="#arguments.payload#" endpoint="#endpoint#" username="#_getUserName()#" apiKey="#_getApiKey()#">
			<cfhttp url="#attributes.endpoint#" method="POST">
				<cfhttpparam type="body" value="#attributes.payload#" />
				<cfhttpparam type="header" name="Authorization" value="Basic #ToBase64( attributes.userName & ':' & attributes.apiKey )#" />
			</cfhttp>
		</cfthread>
	</cffunction>

	<cffunction name="_stringToHex" access="private" returntype="string" output="false">
		<cfargument name="stringValue" type="string" required="true" />

		<cfscript>
			var base64Value = toBase64( stringValue );
			var binaryValue = toBinary( base64Value );
			var hexValue    = binaryEncode( binaryValue, "hex" );

			return( lcase( hexValue ) );
		</cfscript>
	</cffunction>

	<cffunction name="_getLogFromRequest" access="private" returntype="struct" output="false">
		<cfscript>
			var logKey = _getRequestKey();

			if ( not StructKeyExists( request, logKey ) ) {
				request.logKey = StructNew();
				_clearLog();
			}

			return request[ logKey ];
		</cfscript>
	</cffunction>

	<cffunction name="_clearLog" access="private" returntype="void" output="false">
		<cfscript>
			var logKey = _getRequestKey();

			request[ logKey ] = {
				  log = ""
				, statusCode = 0
			};
		</cfscript>
	</cffunction>

<!--- getters and setters --->
	<cffunction name="_getEndpoint" access="private" returntype="string" output="false">
		<cfreturn _endpoint>
	</cffunction>
	<cffunction name="_setEndpoint" access="private" returntype="void" output="false">
		<cfargument name="endpoint" type="string" required="true" />
		<cfset _endpoint = arguments.endpoint />
	</cffunction>

	<cffunction name="_getJobPrefix" access="private" returntype="string" output="false">
		<cfreturn _jobPrefix>
	</cffunction>
	<cffunction name="_setJobPrefix" access="private" returntype="void" output="false">
		<cfargument name="jobPrefix" type="string" required="true" />
		<cfset _jobPrefix = arguments.jobPrefix />
	</cffunction>

	<cffunction name="_getUserName" access="private" returntype="string" output="false">
		<cfreturn _userName>
	</cffunction>
	<cffunction name="_setUserName" access="private" returntype="void" output="false">
		<cfargument name="userName" type="string" required="true" />
		<cfset _userName = arguments.userName />
	</cffunction>

	<cffunction name="_getApiKey" access="private" returntype="string" output="false">
		<cfreturn _apiKey>
	</cffunction>
	<cffunction name="_setApiKey" access="private" returntype="void" output="false">
		<cfargument name="apiKey" type="string" required="true" />
		<cfset _apiKey = arguments.apiKey />
	</cffunction>

	<cffunction name="_getRequestKey" access="private" returntype="string" output="false">
		<cfreturn _requestKey>
	</cffunction>
	<cffunction name="_setRequestKey" access="private" returntype="void" output="false">
		<cfargument name="requestKey" type="string" required="true" />
		<cfset _requestKey = arguments.requestKey />
	</cffunction>

</cfcomponent>