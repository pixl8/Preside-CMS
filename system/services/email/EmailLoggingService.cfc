/**
 * Service that provides logic for logging email sends and updates to email delivery status
 *
 * @autodoc        true
 * @singleton      true
 * @presideService true
 */
component {

// CONSTRUCTOR
	/**
	 * @recipientTypeService.inject emailRecipientTypeService
	 *
	 */
	public any function init( required any recipientTypeService ) {
		_setRecipientTypeService( arguments.recipientTypeService );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Creates an email log entry and returns its ID (useful for future
	 * status updates to email delivery)
	 *
	 * @autodoc            true
	 * @template.hint      ID of the email template that is being sent
	 * @recipientType.hint ID of the recipient type configured for the template
	 * @recipient.hint     email address of the recipient
	 * @sender.hint        email address of the sender
	 * @subject.hint       Subject line of the email
	 * @sendArgs.hint      Structure of args that were original sent to the email send() method
	 */
	public string function createEmailLog(
		  required string template
		, required string recipientType
		, required string recipient
		, required string sender
		, required string subject
		,          struct sendArgs = {}
	) {
		var data = {
			  email_template = arguments.template
			, recipient      = arguments.recipient
			, sender         = arguments.sender
			, subject        = arguments.subject
		};

		if ( Len( Trim( arguments.recipientType ) ) ) {
			data.append( _getAdditionalDataForRecipientType( arguments.recipientType, arguments.sendArgs ) );
		}

		return $getPresideObject( "email_template_send_log" ).insertData( data );
	}


// PRIVATE HELPERS
	private struct function _getAdditionalDataForRecipientType( required string recipientType, required struct sendArgs ) {
		if ( !recipientType.len() ) {
			return {};
		}

		var fkColumn = _getRecipientTypeService().getRecipientIdLogPropertyForRecipientType( recipientType );

		if ( !fkColumn.len() ){
			return {};
		}

		var recipientId = _getRecipientTypeService().getRecipientId( recipientType, sendArgs );

		if ( !recipientId.len() ) {
			return {};
		}

		return { "#fkColumn#" = recipientId };
	}

// GETTERS AND SETTERS
	private any function _getRecipientTypeService() {
		return _recipientTypeService;
	}
	private void function _setRecipientTypeService( required any recipientTypeService ) {
		_recipientTypeService = arguments.recipientTypeService;
	}

}