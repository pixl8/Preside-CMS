component {

	property name="emailService"       inject="emailService";
	property name="formBuilderService" inject="formBuilderService";

	private void function onSubmit( event, rc, prc, args={} ) {
		var replyToField = args.configuration.reply_to ?: "";
		var replyTo      = [];
		var submission   = deserializeJSON( args.submissionData.submitted_data ?: "{}" );

		if ( len( replyToField ) ) {
			var formItem = formBuilderService.getFormItem( replyToField );
			var email    = submission[ formItem.configuration.name ] ?: "";

			if ( len( email ) ) {
				replyTo.append( email );
			}
		}

		emailService.send(
			  template = "formbuilderSubmissionNotification"
			, args     = args
			, to       = ListToArray( args.configuration.recipients ?: "", ";," )
			, from     = args.configuration.send_from ?: ""
			, replyTo  = replyTo
		);
	}

	private string function renderAdminPlaceholder( event, rc, prc, args={} ) {
		var placeholder = '<i class="fa fa-fw fa-envelope"></i> ';
		var toAddress   = HtmlEditFormat( args.configuration.recipients ?: "" );
		var fromAddress = HtmlEditFormat( args.configuration.send_from  ?: "" );

		if ( Len( Trim( fromAddress ) ) ) {
			placeholder &= translateResource(
				  uri  = "formbuilder.actions.email:admin.placeholder.with.from.address"
				, data = [ "<strong>#toAddress#</strong>", "<strong>#fromAddress#</strong>" ]
			);
		} else {
			placeholder &= translateResource(
				  uri  = "formbuilder.actions.email:admin.placeholder.no.from.address"
				, data = [ "<strong>#toAddress#</strong>" ]
			);
		}

		return placeholder;
	}
}