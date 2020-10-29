<cfcomponent output="false">


<!--- CONSTRUCTOR --->
	<cffunction name="init" access="public" returntype="any" output="false">
		<cfscript>
			return this;
		</cfscript>
	</cffunction>

<!--- PUBLIC METHODS --->
	<cffunction name="setVar" access="public" returntype="void" hint="Set a new permanent variable." output="false">
		<cfargument name="name"  type="string" required="true" hint="The name of the variable.">
		<cfargument name="value" type="any"    required="true" hint="The value to set in the variable.">

		<cfset var storage = getStorage()>

		<cfset storage[arguments.name] = arguments.value>
	</cffunction>

	<cffunction name="getVar" access="public" returntype="any" hint="Get a new permanent variable. If the variable does not exist. The method returns blank." output="false">
		<cfargument name="name"    type="string" required="true"  hint="The variable name to retrieve.">
		<cfargument name="default" type="any"    required="false" hint="The default value to set. If not used, a blank is returned." default="">

		<cfset var storage = getStorage()>
		<cfset var results = "">

		<cfscript>
			if ( StructKeyExists( storage, arguments.name ) ) {
				results = storage[arguments.name];
			} else {
				results = arguments.default;
			}
		</cfscript>

		<cfreturn results>
	</cffunction>

	<cffunction name="deleteVar" access="public" returntype="boolean" hint="Tries to delete a permanent session var." output="false">
		<cfargument  name="name" type="string" required="true" 	hint="The variable name to retrieve.">

		<cfset var results = false>
		<cfset var storage = getStorage()>

		<cfset results = StructDelete( storage, arguments.name, true )>

		<cfreturn results>
	</cffunction>

	<cffunction name="exists" access="public" returntype="boolean" hint="Checks wether the permanent variable exists." output="false">
		<cfargument  name="name" type="string" required="true" 	hint="The variable name to retrieve.">

		<cfif NOT StructKeyExists( variables, "_presideStorage" )>
			<cfreturn false>
		<cfelse>
			<cfreturn StructKeyExists( getStorage(), arguments.name )>
		</cfif>
	</cffunction>

	<cffunction name="clearAll" access="public" returntype="void" hint="Clear the entire coldbox session storage" output="false">
		<cfset var storage = getStorage()>

		<cfset StructClear( storage )>
	</cffunction>

	<cffunction name="getStorage" access="public" returntype="any" hint="Get the entire storage scope" output="false" >
		<cfscript>
			_createStorage();
			return _presideStorage;
		</cfscript>
	</cffunction>

	<cffunction name="removeStorage" access="public" returntype="void" hint="remove the entire storage scope" output="false" >
		<cfset StructDelete( variables, "_presideStorage" )>
	</cffunction>

	<cffunction name="rotate" access="public" returntype="void" output="false">
		<!--- DUMMY --->
	</cffunction>

<!--- PRIVATE HELPERS --->

	<cffunction name="_createStorage" access="private" returntype="void" hint="Create the session storage scope" output="false" >

		<cfif not StructKeyExists( variables, "_presideStorage" )>
			<cfset variables["_presideStorage"] = StructNew() />
		</cfif>
	</cffunction>


</cfcomponent>