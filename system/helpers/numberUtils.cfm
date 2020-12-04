<cffunction name="presideStandardNumberFormat" access="public" returntype="string" output="false">
	<cfargument name="number" type="numeric" required="true" />

	<cfscript>
		var decimalPlaces = len( listRest( arguments.number, "." ) );
		var numberFormat = decimalPlaces ? ",.#repeatString( "_", decimalPlaces )#" : ",";
	</cfscript>

	<cfreturn lsNumberFormat( arguments.number, numberFormat ) />
</cffunction>