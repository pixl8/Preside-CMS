/**
 * @presideService     true
 * @validationProvider true
 * @singleton          true
 * @feature            emailCenter
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

	public string function allowedSenderEmail_js() {
		return "function(){ return true; }";
	}

	public array function existingEmailsUsingInvalidDomains( required string validDomains ) {
		var delims    = ", #Chr( 10 )##Chr( 13 )#";
		var domains   = ListToArray( Trim( arguments.validDomains ), delims );
		var addresses = $getPresideObject( "email_template" ).selectData(
			  distinct     = true
			, filter       = "from_address IS NOT NULL"
			, selectFields = [ "id","from_address", "is_system_email" ]
		);
		var badaddresses = [];

		for( var address in addresses ) {
			var domain = _getDomainFromEmail( address.from_address );
			if ( !ArrayFindNoCase( domains, domain ) ) {
				if ( isBoolean( address.is_system_email ?: "" ) && address.is_system_email &&
					!_getSystemEmailTemplateService().templateExists( address.id )
				) {
					$getPresideObject( "email_template" ).updateData(  id=address.id, data={ from_address="" } );
				} else {
					ArrayAppend( badaddresses, address.from_address );
				}
			}
		}

		return badaddresses;
	}

	public array function formbuilderActionsUsingInvalidDomains( required string validDomains ) {
		var delims       = ", #Chr( 10 )##Chr( 13 )#";
		var domains      = ListToArray( Trim( arguments.validDomains ), delims );
		var formactions  = $getPresideObject( "formbuilder_formaction" ).selectData(
			  distinct     = true
			, filter       = { action_type="email" }
			, selectFields = [ "configuration" ]
		);
		var badaddresses = [];

		for( var formaction in formactions ) {
			var config   = formaction.configuration;
			if ( !IsJSON( config ) ) {
				continue;
			}
			config       = DeserializeJSON( config );
			var sendFrom = Trim( config.send_from ?: "" );
			if ( !Len( sendFrom ) ) {
				continue;
			}
			var domain   = _getDomainFromEmail( sendFrom );
			if ( !ArrayFindNoCase( domains, domain ) && !ArrayFindNoCase( badaddresses, sendFrom ) ) {
				ArrayAppend( badaddresses, sendFrom );
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