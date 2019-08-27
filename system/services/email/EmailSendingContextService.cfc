/**
 * Service to provide logic for setting, unsetting and getting
 * current recipient context during email sends.
 * \n
 * This allows external logic to check for a user for widget
 * contexts, etc.
 *
 * @singleton      true
 * @presideService true
 * @autodoc        true
 */
component {

	variables._requestKey = "__emailSendingContext" & CreateObject('java','java.lang.System').identityHashCode( this );

// CONSTRUCTOR
	/**
	 * @recipientTypeService.inject emailRecipientTypeService
	 *
	 */
	public any function init( required any recipientTypeService ) {
		_setRecipientTypeService( arguments.recipientTypeService );

		return this;
	}

// PUBLIC API
	/**
	 * Returns a payload for use in rules engine conditions
	 * etc. for the current email sending context. Returns
	 * an empty struct if there is no context.
	 *
	 * @autodoc true
	 */
	public struct function getContextPayload() {
		var context = getContext();
		var payload = {};

		if ( !context.isEmpty() ) {
			if ( !StructKeyExists( context, "payload" ) ) {
				var recipientObject = _getRecipientTypeService().getFilterObjectForRecipientType( context.recipientType ?: "" );

				if ( recipientObject.len() ) {
					var recipient = $getPresideObjectService().selectData(
						  objectName = recipientObject
						, id         = ( context.recipientId ?: "" )
					);

					for( var r in recipient ) {
						payload[ recipientObject ] = r;
						break;
					}
				}

				context.payload = payload;
			}

			$announceInterception( "onGetEmailContextPayload", context );
			payload = context.payload;
		}

		return payload;
	}

	/**
	 * Sets the context for the email send.
	 *
	 * @autodoc            true
	 * @recipientType.hint The email system recipient type that is being sent to
	 * @recipientId.hint   The ID of the recipient that is being sent to
	 * @templateId.hint    The ID of the template being rendered/sent
	 * @template.hint      Struct with details of the template being rendered/sent
	 */
	public void function setContext(
		  required string recipientType
		, required string recipientId
		,          string templateId = ""
		,          struct template   = {}
	) {
		request[ _requestKey ] = {
			  recipientType = arguments.recipientType
			, recipientId   = arguments.recipientId
			, templateId    = arguments.templateId
			, template      = arguments.template
		};
	}

	/**
	 * Clears the context for the email send (i.e. sending is over)
	 *
	 * @autodoc            true
	 */
	public void function clearContext() {
		request[ _requestKey ] = {};
	}

	/**
	 * Clears the context for the email send (i.e. sending is over)
	 *
	 * @autodoc true
	 */
	public struct function getContext() {
		request[ _requestKey ] = request[ _requestKey ] ?: {};

		return request[ _requestKey ];
	}

// GETTERS AND SETTERS
	private any function _getRecipientTypeService() {
		return _recipientTypeService;
	}
	private void function _setRecipientTypeService( required any recipientTypeService ) {
		_recipientTypeService = arguments.recipientTypeService;
	}
}