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
		, required string recipientId
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
			, send_args      = SerializeJson( arguments.sendArgs )
		};

		if ( Len( Trim( arguments.recipientType ) ) ) {
			data.append( _getAdditionalDataForRecipientType( arguments.recipientType, arguments.recipientId, arguments.sendArgs ) );
		}

		return $getPresideObject( "email_template_send_log" ).insertData( data );
	}

	/**
	 * Marks the given email as sent
	 *
	 * @autodoc true
	 * @id.hint ID of the email to mark as sent
	 *
	 */
	public void function markAsSent( required string id ) {
		$getPresideObject( "email_template_send_log" ).updateData( id=arguments.id, data={
			  sent      = true
			, sent_date = _getNow()
		} );
	}

	/**
	 * Marks the given email as delivered
	 *
	 * @autodoc true
	 * @id.hint ID of the email to mark as delivered
	 *
	 */
	public void function markAsDelivered( required string id ) {
		$getPresideObject( "email_template_send_log" ).updateData(
			  filter       = "id = :id and ( delivered is null or delivered = :delivered )"
			, filterParams = { id=arguments.id, delivered=false }
			, data         = {
				  delivered      = true
				, delivered_date = _getNow()
			  }
		);
	}

	/**
	 * Marks the given email as opened
	 *
	 * @autodoc true
	 * @id.hint ID of the email to mark as opened
	 *
	 */
	public void function markAsOpened( required string id ) {
		$getPresideObject( "email_template_send_log" ).updateData(
			  filter       = "id = :id and ( opened is null or opened = :opened )"
			, filterParams = { id=arguments.id, opened=false }
			, data         = {
				  opened      = true
				, opened_date = _getNow()
			  }
		);

		markAsDelivered( arguments.id );
	}

	/**
	 * Inserts a tracking pixel into the given HTML email
	 * content (based on the given message ID). Returns
	 * the HTML with the inserted tracking pixel
	 *
	 * @autodoc          true
	 * @messageId.hint   ID of the message (log id)
	 * @messageHtml.hint HTML content of the message
	 */
	public string function insertTrackingPixel(
		  required string messageId
		, required string messageHtml
	) {
		var trackingUrl   = $getRequestContext().buildLink( linkto="email.tracking.open", queryString="mid=" & arguments.messageId );
		var trackingPixel = "<img src=""#trackingUrl#"" width=""1"" height=""1"" style=""width:1px;height:1px"" />";

		if ( messageHtml.findNoCase( "</body>" ) ) {
			return messageHtml.replaceNoCase( "</body>", trackingPixel & "</body>" );
		}

		return messageHtml & trackingPixel;
	}

	/**
	 * Records an activity performed against an specific sent email.
	 * e.g. opened, clicked link, etc.
	 *
	 * @autodoc true
	 * @messageId.hint ID of the message (send log) to record against
	 * @activity.hint  The activity type performed (see system ENUM, `emailActivityType`)
	 * @extraData.hint Structure of additional data that may be useful in email send log viewer (e.g. URL of clicked link)
	 *
	 */
	public void function recordActivity(
		  required string messageId
		, required string activity
		,          struct extraData = {}
	) {
		$getPresideObject( "email_template_send_log_activity" ).insertData({
			  message       = arguments.messageId
			, activity_type = arguments.activity
			, user_ip       = cgi.remote_addr
			, user_agent    = cgi.http_user_agent
			, extra_data    = SerializeJson( arguments.extraData )
		});
	}

// PRIVATE HELPERS
	private struct function _getAdditionalDataForRecipientType( required string recipientType, required string recipientId, required struct sendArgs ) {
		if ( !recipientType.len() ) {
			return {};
		}

		var fkColumn = _getRecipientTypeService().getRecipientIdLogPropertyForRecipientType( recipientType );

		if ( !fkColumn.len() ){
			return {};
		}

		return { "#fkColumn#" = arguments.recipientId };
	}

	private date function _getNow() {
		return Now(); // abstracting this makes testing easier
	}

// GETTERS AND SETTERS
	private any function _getRecipientTypeService() {
		return _recipientTypeService;
	}
	private void function _setRecipientTypeService( required any recipientTypeService ) {
		_recipientTypeService = arguments.recipientTypeService;
	}

}