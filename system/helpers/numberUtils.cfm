<cffunction name="presideStandardNumberFormat" access="public" returntype="string" output="false">
	<cfargument name="number" type="numeric" required="true" />
	<cfargument name="mask"   type="string"  required="false" default="" />
	<cfargument name="locale" type="string"  required="false" default="" /><cfsilent>

	<cfscript>
		var resolvedMask  = Len( arguments.mask ) ? arguments.mask : getSingleton( "numberFormatService" ).getNumberFormatMask( arguments.locale );
		var decimalPlaces = Len( ListRest( arguments.number, "." ) );
		var numberFormat  = decimalPlaces ? "#resolvedMask#.#RepeatString( '_', decimalPlaces )#" : resolvedMask;
	</cfscript>

	<cfreturn lsNumberFormat( arguments.number, numberFormat ) />
</cfsilent></cffunction>