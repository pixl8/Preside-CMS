<cfscript>
	public string function prepareSourceStringForBatchOperations( required struct selectDataArgs ) output=false {
		arguments.selectDataArgs.delete( "maxRows" );
		arguments.selectDataArgs.delete( "startRow" );

		var serialized        = serializeJson( selectDataArgs );
		var obfuscated        = toBase64( serialized );
		var hashForValidation = hash( obfuscated );

		getSingleton( "sessionStorage" ).setVar( hashForValidation, 1 );

		return obfuscated;
	}

	public struct function deserializeSourceStringForBatchOperations( event, rc, prc, listingUrl ) output=false {
		var src = rc.batchSrcArgs ?: "";

		if ( len( trim( src ) ) ) {
			var hashForValidation = hash( rc.batchSrcArgs );

			if ( getSingleton( "sessionStorage" ).exists( hashForValidation ) ) {
				var asJson = toString( toBinary( src ) );
				if ( isJson( asJson ) ) {
					return deserializeJson( asJson );
				}
			}
		}

		getSingleton( "messagebox@cbmessagebox" ).error( translateResource( "cms:datamanager.norecordsselected.error" ) );
		setNextEvent( url=arguments.listingUrl );
	}
</cfscript>