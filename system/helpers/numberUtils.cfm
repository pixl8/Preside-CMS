<cffunction name="numberThousandDecimalFormat" access="public" returntype="string" output="false">
	<cfargument name="number" type="numeric" required="true" />
	<cfargument name="decimals" type="numeric" required="false" default="0" />

	<cfscript>
		var decimalPlaceholder = "";

		if( round( arguments.number ) != arguments.number || arguments.decimals > 0 ) {
			var decimalsCount = 0;

			if( arguments.decimals > 0 ) {
				decimalsCount = arguments.decimals;
			}
			else {
				decimalsCount = len( arrayLast( listToArray( arguments.number, "." ) ) );
			}

			for( var i = 1; i <= decimalsCount; i++ ) {
				decimalPlaceholder &= "9";
			}

			if( !isEmptyString( decimalPlaceholder ) ) {
				decimalPlaceholder = "." & decimalPlaceholder;
			}
		}
	</cfscript>

	<cfreturn numberFormat( arguments.number, ",#decimalPlaceholder#" ) />
</cffunction>