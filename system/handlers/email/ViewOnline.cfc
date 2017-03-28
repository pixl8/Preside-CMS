/**
 * Handler used for viewing email's online
 *
 */
component {

	property name="emailTemplateService" inject="emailTemplateService";

	public string function index( event, rc, prc ) {
		var messageId = Trim( rc.mid ?: "" );
		var htmlMessage = emailTemplateService.getViewOnlineContent( messageId );

		if ( htmlMessage.len() ) {
			return htmlMessage;
		}

		event.notFound();
	}
}