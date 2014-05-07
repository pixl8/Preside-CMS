<cfcomponent output="false" hint="I am a base Service object. All front-end services should extend me">

	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="presideObjectService"  type="any" required="true" />
		<cfargument name="logger"                type="any" required="true" />

		<cfscript>
			_setPresideObjectService( arguments.presideObjectService );
			_setLogger( arguments.logger );

			return this;
		</cfscript>
	</cffunction>

<!--- shared utility methods --->
	<cffunction name="getPresideObject" access="private" returntype="any" output="false">
		<cfargument name="objectName" type="string" required="true" />

		<cfreturn _getPresideObjectService().getObject( objectName = arguments.objectName ) />
	</cffunction>
	<cffunction name="presideObjectExists" access="private" returntype="any" output="false">
		<cfreturn _getPresideObjectService().presideObjectExists( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="fieldExists" access="public" returntype="boolean" output="false">
		<cfreturn _getPresideObjectService().fieldExists( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="dataExists" access="private" returntype="any" output="false">
		<cfreturn _getPresideObjectService().dataExists( argumentCollection = arguments ) />
	</cffunction>
	<cffunction name="deleteData" access="private" returntype="any" output="false">
		<cfreturn _getPresideObjectService().deleteData( argumentCollection = arguments ) />
	</cffunction>
	<cffunction name="insertData" access="private" returntype="any" output="false">
		<cfreturn _getPresideObjectService().insertData( argumentCollection = arguments ) />
	</cffunction>
	<cffunction name="updateData" access="private" returntype="any" output="false">
		<cfreturn _getPresideObjectService().updateData( argumentCollection = arguments ) />
	</cffunction>
	<cffunction name="selectData" access="private" returntype="any" output="false">
		<cfreturn _getPresideObjectService().selectData( argumentCollection = arguments ) />
	</cffunction>

	<cffunction name="getRelatedObjects" access="private" returntype="query" output="false">
		<cfreturn _getRelatedObjectsService().getRelationships( argumentCollection = arguments ) />
	</cffunction>

<!--- getters and setters --->
	<cffunction name="_getPresideObjectService" access="private" returntype="any" output="false">
		<cfreturn _presideObjectService>
	</cffunction>
	<cffunction name="_setPresideObjectService" access="private" returntype="void" output="false">
		<cfargument name="presideObjectService" type="any" required="true" />
		<cfset _presideObjectService = arguments.presideObjectService />
	</cffunction>

	<cffunction name="_getLogger" access="private" returntype="any" output="false">
		<cfreturn _logger>
	</cffunction>
	<cffunction name="_setLogger" access="private" returntype="void" output="false">
		<cfargument name="logger" type="any" required="true" />
		<cfset _logger = arguments.logger />
	</cffunction>
</cfcomponent>