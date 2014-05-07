<cffunction name="removeEmptyStructKeys" access="public" returntype="struct" output="false">
	<cfargument name="inputStruct" type="struct" required="true" />

	<cfscript>
		var result = Duplicate( inputStruct );
		var key    = "";

		for( key in result ) {
			if ( IsNull( result[ key ] ) or ( IsSimpleValue( result[ key ] ) and not Len( Trim( result[ key ] ) ) ) ) {
				StructDelete( result, key );
			}
		}

		return result;
	</cfscript>
</cffunction>