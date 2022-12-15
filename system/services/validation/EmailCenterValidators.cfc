/**
 * @presideService     true
 * @validationProvider true
 * @singleton          true
 */
component {

	/**
	 * @systemEmailTemplateService.inject    SystemEmailTemplateService
	 */
	public any function init(
		required any systemEmailTemplateService
	) {
		_setSystemEmailTemplateService( arguments.systemEmailTemplateService );

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

		var emailDomain = _getDomainFromEmail( arguments.value );
		for( var allowedDomain in allowedDomains ) {
			if ( emailDomain == Trim( allowedDomain ) ) {
				return true;
			}
		}

		return false;
	}

	public array function existingEmailsUsingInvalidDomains( required string validDomains ) {
		var delims    = ", #Chr( 10 )##Chr( 13 )#";
		var domains   = ListToArray( Trim( arguments.validDomains ), delims );
		var addresses = $getPresideObject( "email_template" ).selectData(
			  distinct     = true
			, selectFields = [ "id","from_address" ]
		);
		var badaddresses = [];

		for( var address in addresses ) {
			if ( Len( address.from_address) ) {
				if ( _getSystemEmailTemplateService().templateExists( address.id ) ) {
					var domain = _getDomainFromEmail( address.from_address );
					if ( !ArrayFindNoCase( domains, domain ) ) {
						ArrayAppend( badaddresses, address.from_address );
					}
				} else {
					$getPresideObject( "email_template" ).updateData(  id=address.id, data={ from_address="" } );
				}
			}
		}

		return badaddresses;
	}

	// PRIVATE HELPERs
	private string function _getDomainFromEmail( required string emailAddress ) {
		return ReReplace( Trim( arguments.emailAddress ), ".*?@(.*?)>?$", "\1" );
	}

	// GETTERs & SETTERs
	private any function _getSystemEmailTemplateService() {
		return _systemEmailTemplateService;
	}
	private void function _setSystemEmailTemplateService( required any systemEmailTemplateService ) {
		_systemEmailTemplateService = arguments.systemEmailTemplateService;
	}
}