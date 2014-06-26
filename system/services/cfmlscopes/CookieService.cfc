<cfcomponent output="false" singleton="true">

<!--- CONSTRUCTOR --->
	<cffunction name="init" access="public" returntype="any" output="false" hint="Constructor">
		<cfargument name="encryptionKey" type="string"  required="false" default="" />

		<cfscript>
			_setEncryptionAlgorithm( "CFMX_COMPAT" );
			_setEncryptionEncoding( "HEX" );
			_setEncryptionKey( arguments.encryptionKey );
			_setEncryption( Len( Trim( arguments.encryptionKey ) ) );

			return this;
		</cfscript>
	</cffunction>

<!--- PUBLIC METHODS --->
	<cffunction name="setVar" access="public" returntype="void" hint="Set a new permanent variable in the storage." output="false">
		<cfargument name="name"     type="string"  required="true"                    hint="The name of the variable.">
		<cfargument name="value"    type="any"     required="true"                    hint="The value to set in the variable, simple, array, query or structure.">
		<cfargument name="expires"  type="numeric" required="false" default="0"       hint="Cookie Expire in number of days. [default cookie is session only = 0 days]">
		<cfargument name="secure"   type="boolean" required="false" default="false"   hint="If browser does not support Secure Sockets Layer (SSL) security, the cookie is not sent. To use the cookie, the page must be accessed using the https protocol.">
		<cfargument name="path"     type="string"  required="false" default=""        hint="URL, within a domain, to which the cookie applies; typically a directory. Only pages in this path can use the cookie. By default, all pages on the server that set the cookie can access the cookie.">
		<cfargument name="domain"   type="string"  required="false" default=""        hint="Domain in which cookie is valid and to which cookie content can be sent from the user's system.">
		<cfargument name="httpOnly" type="string"  required="false" default="false"   hint="HTTP Only cookies are not accesible by javascript and cannot therefor be stolen by XSS and CSRF attacks (use httpOnly cookies for keep me logged in, etc.)">

		<cfset var tmpVar	= "">
		<cfset var args		= StructNew()>

		<cfset tmpVar = serializeJSON( arguments.value )>

		<cfif _getEncryption()>
			<cfset tmpVar = _encryptIt( tmpVar )>
		</cfif>

		<cfset args["name"]		= uCase( arguments.name ) />
		<cfset args["value"]	= tmpVar />
		<cfset args["secure"]	= arguments.secure />
		<cfset args["httpOnly"]	= arguments.httpOnly />
		<cfif arguments.expires GT 0>
			<cfset args["expires"] = arguments.expires />
		</cfif>
		<cfif len( arguments.path ) GT 0 and not len( arguments.domain ) GT 0>
			<cfthrow type="CookieStorage.MissingDomainArgument" message="If you specify path, you must also specify domain.">
		<cfelseif len( arguments.path ) GT 0 and len( arguments.domain ) GT 0>
			<cfset args["path"]		= arguments.path />
			<cfset args["domain"]	= arguments.domain />
		<cfelseif len( arguments.domain )>
			<cfset args["domain"]	= arguments.domain />
		</cfif>

		<cfcookie attributeCollection="#args#" />
	</cffunction>

	<cffunction name="getVar" access="public" returntype="any" hint="Get a new permanent variable. If the cookie does not exist. The method returns blank or use the default value argument" output="false">
		<cfargument name="name"    required="true"             hint="The variable name to retrieve.">
		<cfargument name="default" required="false" default="" hint="The default value to set. If not used, a blank is returned.">

		<cfset var rtnVar = "">

		<cfif exists(arguments.name)>
			<cfset rtnVar = cookie[ uCase( arguments.name ) ]>

			<cfif _getEncryption() and len( rtnVar )>
				<cfset rtnVar = _decryptIt( rtnVar )>
			</cfif>

			<cfif isJSON( rtnVar )>
				<cfset rtnVar = deserializeJSON( rtnVar )>
			</cfif>
			<cfreturn rtnVar>
		<cfelseif structKeyExists(arguments, "default")>
			<cfreturn arguments.default>
		<cfelse>
			<cfthrow type="CookieStorage.InvalidKey" message="The key you requested: #arguments.name# does not exist">
		</cfif>
	</cffunction>

	<cffunction name="exists" access="public" returntype="boolean" hint="Checks wether the permanent variable exists in the storage" output="false">
		<cfargument name="name" type="string" required="true" hint="The variable name to retrieve.">

		<cfreturn StructKeyExists( cookie, uCase( arguments.name ) )>
	</cffunction>

	<cffunction name="deleteVar" access="public" returntype="boolean" hint="Tries to delete a permanent cookie variable" output="false">
		<cfargument name="name"   type="string" required="true"             hint="The variable name to retrieve.">
		<cfargument name="domain" type="string" required="false" default="" hint="Domain in which cookie is valid and to which cookie content can be sent from the user's system.">

		<cfset var args		= StructNew() />

		<cfif exists(arguments.name)>
			<cfset args["name"] 	= ucase(arguments.name) />
			<cfset args["expires"]	= "NOW" />
			<cfset args["value"]	= "" />
			<cfif len(arguments.domain)>
				<cfset args["domain"]	= arguments.domain />
			</cfif>
			<cfcookie attributeCollection="#args#">
			<cfset structdelete(cookie, arguments.name)>
			<cfreturn true>
		<cfelse>
			<cfreturn false>
		</cfif>
	</cffunction>

<!--- PRIVATE HELPERS --->
	<cffunction name="_encryptIt" access="private" returntype="any" hint="Return encrypted value" output="false">
		<cfargument name="encValue" hint="string to be encrypted" required="true" type="string" />
		<cfreturn Encrypt( arguments.encValue, _getEncryptionKey(), _getEncryptionAlgorithm(), _getEncryptionEncoding() ) />
	</cffunction>

	<cffunction name="_decryptIt" access="private" returntype="any" hint="Return decrypted value" output="false">
		<cfargument name="decValue" hint="string to be decrypted" required="true" type="string" />
		<cfreturn Decrypt( arguments.decValue, _getEncryptionKey(), _getEncryptionAlgorithm(), _getEncryptionEncoding() ) />
	</cffunction>

<!--- GETTERS & SETTERS --->
	<cffunction name="_getEncryptionKey" access="public" output="false" returntype="string" hint="Get the EncryptionKey">
		<cfreturn instance.EncryptionKey/>
	</cffunction>
	<cffunction name="_setEncryptionKey" access="public" output="false" returntype="void" hint="Set EncryptionKey for this storage">
		<cfargument name="EncryptionKey" type="string" required="true"/>
		<cfset instance.EncryptionKey = arguments.EncryptionKey/>
	</cffunction>

	<cffunction name="_getEncryptionAlgorithm" access="public" output="false" returntype="string" hint="Get the EncryptionAlgorithm">
		<cfreturn instance.EncryptionAlgorithm/>
	</cffunction>
	<cffunction name="_setEncryptionAlgorithm" access="public" output="false" returntype="void" hint="Set EncryptionAlgorithm for this storage">
		<cfargument name="EncryptionAlgorithm" type="string" required="true"/>
		<cfset instance.EncryptionAlgorithm = arguments.EncryptionAlgorithm/>
	</cffunction>

	<cffunction name="_getEncryption" access="public" output="false" returntype="boolean" hint="Get Encryption flag">
		<cfreturn instance.Encryption/>
	</cffunction>
	<cffunction name="_setEncryption" access="public" output="false" returntype="void" hint="Set Encryption flag">
		<cfargument name="Encryption" type="boolean" required="true"/>
		<cfset instance.Encryption = arguments.Encryption/>
	</cffunction>

	<cffunction name="_getEncryptionEncoding" access="public" output="false" returntype="string" hint="Get EncryptionEncoding value">
		<cfreturn instance.EncryptionEncoding/>
	</cffunction>
	<cffunction name="_setEncryptionEncoding" access="public" output="false" returntype="void" hint="Set EncryptionEncoding value">
		<cfargument name="EncryptionEncoding" type="string" required="true"/>
		<cfset instance.EncryptionEncoding = arguments.EncryptionEncoding/>
	</cffunction>


</cfcomponent>