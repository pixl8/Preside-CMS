component {

	property name="emailTemplateService" inject="EmailTemplateService";

	private void function runAsync() {
		var templates = emailTemplateService.getTemplates( custom=true );

		for ( var template in templates ) {
			var lastLog = getPresideObject( "email_template_send_log" ).selectData(
				  selectFields = [ "Max( sent_date ) as sent_date" ]
				, filter       = { email_template = template.id }
			);

			if ( !isEmptyString( lastLog.sent_date ?: "" ) ) {
				emailTemplateService.updateLastSentDate( template.id, lastLog.sent_date );
			}
		}
	}

}