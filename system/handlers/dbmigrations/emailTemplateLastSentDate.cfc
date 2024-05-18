/**
 * @feature emailCenter
 */
component {

	property name="emailTemplateService" inject="featureInjector:emailCenter:EmailTemplateService";

	private void function runAsync() {
		var templates = emailTemplateService.getTemplates( custom=true );

		for ( var template in templates ) {
			var lastLog = getPresideObject( "email_template_send_log" ).selectData(
				  selectFields = [
					"sent_date"
				  ]
				, filter       = {
					email_template = template.id
				 }
				, orderBy      = "sent_date desc"
				, maxRows      = 1
			);

			if ( !isEmptyString( lastLog.sent_date ?: "" ) ) {
				emailTemplateService.updateLastSentDate( template.id, lastLog.sent_date );
			}
		}
	}

}