<cfcomponent displayname="Logger" hint="Log related functions" output="false" extends="_baseLogger">

<!--- constructor --->
	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="defaultLog"         type="string"  required="true" />
		<cfargument name="logApplicationName" type="boolean" required="false" default="false" />
		<cfargument name="logThreadName"      type="boolean" required="false" default="false" />

		<cfscript>
			super.init( argumentCollection = arguments );

			_setDefaultLog( arguments.defaultLog );
			_setLogApplicationName( arguments.logApplicationName );
			_setLogThreadName( arguments.logThreadName );

			return this;
		</cfscript>
	</cffunction>

<!--- private methods --->
	<cffunction name="_log" access="private" returntype="void" output="false">
		<cfargument name="type" type="string" required="true">
		<cfargument name="text" type="string" required="true">
		<cfif server.coldfusion.productname NEQ "Railo" AND server.coldfusion.productname NEQ 'Lucee'>
		 	<cflog type        = "#arguments.type#"
			       text        = "#arguments.text#"
			       file        = "#_getDefaultLog()#_#DateFormat( Now(), 'yyyy-mm-dd' )#"
			       application = "#_getLogApplicationName()#"
			       thread      = "#_getLogThreadName()#" />
		<cfelse>
			<!--- thread attribute is deprecated in Railo --->
		   	<cflog type        = "#arguments.type#"
			       text        = "#arguments.text#"
			       file        = "#_getDefaultLog()#_#DateFormat( Now(), 'yyyy-mm-dd' )#"
			       application = "#_getLogApplicationName()#"/>
		 </cfif>


	</cffunction>

<!--- getters and setters --->
	<cffunction name="_getDefaultLog" access="private" returntype="string" output="false">
		<cfreturn _DefaultLog />
	</cffunction>
	<cffunction name="_setDefaultLog" access="private" returntype="void" output="false">
		<cfargument name="DefaultLog" type="string" required="true" />
		<cfset _DefaultLog = arguments.DefaultLog />
	</cffunction>

	<cffunction name="_getLogApplicationName" access="private" returntype="boolean" output="false">
		<cfreturn _logApplicationName>
	</cffunction>
	<cffunction name="_setLogApplicationName" access="private" returntype="void" output="false">
		<cfargument name="logApplicationName" type="boolean" required="true" />
		<cfset _logApplicationName = arguments.logApplicationName />
	</cffunction>

	<cffunction name="_getLogThreadName" access="private" returntype="boolean" output="false">
		<cfreturn _logThreadName>
	</cffunction>
	<cffunction name="_setLogThreadName" access="private" returntype="void" output="false">
		<cfargument name="logThreadName" type="boolean" required="true" />
		<cfset _logThreadName = arguments.logThreadName />
	</cffunction>
</cfcomponent>