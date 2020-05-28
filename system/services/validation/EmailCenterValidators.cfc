/**
 * @presideService     true
 * @validationProvider true
 * @singleton          true
 */
component {

	public any function init() {
		return;
	}

	public boolean function allowedSenderEmail( required string fieldName, string value="" ) validatorMessage="cms:validation.allowedSenderEmail.default" {
		if ( !Len( Trim( arguments.value ) ) ) {
			return true;
		}

		var rc = $getRequestContext().getContext();
		var allowedDomains = "";
		var delims = ", #Chr( 10 )##Chr( 13 )#";

		if ( Len( Trim( rc.allowed_sending_domains ?: "" ) ) ) {
			allowedDomains = ListToArray( Trim( rc.allowed_sending_domains ), delims );
		} else {
			allowedDomains = ListToArray( Trim( $getPresideSetting( "email", "allowed_sending_domains" ) ), delims );
		}

		if ( !ArrayLen( allowedDomains ) ) {
			return true;
		}

		var emailDomain = Trim( ListRest( arguments.value, "@" ) );
		for( var allowedDomain in allowedDomains ) {
			if ( emailDomain == Trim( allowedDomain ) ) {
				return true;
			}
		}

		return false;
	}

}