/**
 * Signs the ObjectPicker parameters that decide which records an ajax search returns.
 * The key lives in the admin session, so a signature cannot be reused in another session.
 *
 * @singleton      true
 * @presideservice true
 */
component {

	property name="sessionStorage" inject="sessionStorage";
	property name="cfsignatures"   inject="cfsignatures@cfsignatures";

	variables.signedParamNames = [
		  "bypassTenants"
		, "filterBy"
		, "filterByField"
		, "labelRenderer"
		, "object"
		, "orderBy"
		, "savedFilters"
		, "sourceObject"
		, "sourceObjectField"
		, "targetIdField"
		, "useCache"
	];
	variables.sessionKeyName = "_ajaxSelectSignatureKey";
	variables.algorithm      = "HS256";

	public any function init() {
		return this;
	}

	public string function sign( required struct params ) {
		return cfsignatures.sign(
			  payload    = _canonical( arguments.params )
			, signingKey = _signingKey()
			, algorithm  = variables.algorithm
		);
	}

	public boolean function isValid( required struct params, required string signature ) {
		return cfsignatures.verify(
			  signature    = Trim( arguments.signature )
			, verifyingKey = _signingKey()
			, payload      = _canonical( arguments.params )
			, algorithm    = variables.algorithm
		);
	}

	private string function _canonical( required struct params ) {
		var parts = [];

		for ( var name in variables.signedParamNames ) {
			var value = Trim( arguments.params[ name ] ?: "" );

			ArrayAppend( parts, name & ":" & Len( value ) & ":" & value );
		}

		return ArrayToList( parts, Chr( 10 ) );
	}

	private string function _signingKey() {
		var key = sessionStorage.getVar( variables.sessionKeyName, "" );

		if ( !Len( Trim( key ) ) || !cfsignatures.validateSigningKey( key=key, algorithm=variables.algorithm ) ) {
			key = cfsignatures.generateKeys( variables.algorithm );
			sessionStorage.setVar( variables.sessionKeyName, key );
		}

		return key;
	}

}
