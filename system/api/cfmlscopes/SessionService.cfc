<cfcomponent output="false">


<!--- CONSTRUCTOR --->
	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="lockTimeout" type="numeric" required="false" default="20" />
		<cfscript>
			_setLockTimeout( arguments.lockTimeout );

			return this;
		</cfscript>
	</cffunction>

<!--- PUBLIC METHODS --->
	<cffunction name="setVar" access="public" returntype="void" hint="Set a new permanent variable." output="false">
		<cfargument name="name"  type="string" required="true" hint="The name of the variable.">
		<cfargument name="value" type="any"    required="true" hint="The value to set in the variable.">

		<cfset var storage = getStorage()>

		<cflock scope="session" type="exclusive" timeout="#_getLockTimeout()#" throwontimeout="true">
			<cfset storage[arguments.name] = arguments.value>
		</cflock>
	</cffunction>

	<cffunction name="getVar" access="public" returntype="any" hint="Get a new permanent variable. If the variable does not exist. The method returns blank." output="false">
		<cfargument name="name"    type="string" required="true"  hint="The variable name to retrieve.">
		<cfargument name="default" type="any"    required="false" hint="The default value to set. If not used, a blank is returned." default="">

		<cfset var storage = getStorage()>
		<cfset var results = "">

		<cflock scope="session" type="readonly" timeout="#_getLockTimeout()#" throwontimeout="true">
			<cfscript>
				if ( StructKeyExists( storage, arguments.name ) ) {
					results = storage[arguments.name];
				} else {
					results = arguments.default;
				}
			</cfscript>
		</cflock>

		<cfreturn results>
	</cffunction>

	<cffunction name="deleteVar" access="public" returntype="boolean" hint="Tries to delete a permanent session var." output="false">
		<cfargument  name="name" type="string" required="true" 	hint="The variable name to retrieve.">

		<cfset var results = false>
		<cfset var storage = getStorage()>

		<cflock scope="session" type="exclusive" timeout="#_getLockTimeout()#" throwontimeout="true">
			<cfset results = StructDelete( storage, arguments.name, true )>
		</cflock>

		<cfreturn results>
	</cffunction>

	<cffunction name="exists" access="public" returntype="boolean" hint="Checks wether the permanent variable exists." output="false">
		<cfargument  name="name" type="string" required="true" 	hint="The variable name to retrieve.">

		<cfif NOT IsDefined( "session" ) OR NOT StructKeyExists( session, "presideStorage" )>
			<cfreturn false>
		<cfelse>
			<cfreturn StructKeyExists( getStorage(), arguments.name )>
		</cfif>
	</cffunction>

	<cffunction name="clearAll" access="public" returntype="void" hint="Clear the entire coldbox session storage" output="false">
		<cfset var storage = getStorage()>

		<cflock scope="session" type="exclusive" timeout="#_getLockTimeout()#" throwontimeout="true">
			<cfset StructClear( storage )>
		</cflock>
	</cffunction>

	<cffunction name="getStorage" access="public" returntype="any" hint="Get the entire storage scope" output="false" >
		<cfscript>
			_createStorage();
			return session.presideStorage;
		</cfscript>
	</cffunction>

	<cffunction name="removeStorage" access="public" returntype="void" hint="remove the entire storage scope" output="false" >
		<cflock scope="session" type="exclusive" timeout="#_getLockTimeout()#" throwontimeout="true">
			<cfset StructDelete( session, "presideStorage" )>
		</cflock>
	</cffunction>

<!--- PRIVATE HELPERS --->

	<cffunction name="_createStorage" access="private" returntype="void" hint="Create the session storage scope" output="false" >
		<cfif IsDefined( "session" ) AND NOT StructKeyExists( session, "presideStorage" )>
			<cflock scope="session" type="exclusive" timeout="#_getLockTimeout()#" throwontimeout="true">
				<cfif not StructKeyExists( session, "presideStorage" )>
					<cfset session["presideStorage"] = StructNew() />
				</cfif>
			</cflock>
		</cfif>
	</cffunction>

<!--- GETTERS & SETTERS --->
	<cffunction name="_getLockTimeout" access="private" returntype="numeric" output="false">
		<cfreturn _lockTimeout>
	</cffunction>
	<cffunction name="_setLockTimeout" access="private" returntype="void" output="false">
		<cfargument name="lockTimeout" type="numeric" required="true" />
		<cfset _lockTimeout = arguments.lockTimeout />
	</cffunction>

</cfcomponent>