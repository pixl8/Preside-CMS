component {

	private struct function prepareMessage( event, rc, prc, args={} ) {

		args.adminLink     = event.buildAdminLink( linkto="formbuilder.submissions", queryString="id=" & ( args.submissionData.form ?: "" ) );
		args.adminLinkText = translateResource( "formbuilder:email.notificatio.admin.link.text" );

		var message = {
			  textBody = renderView( view="/formbuilder/actions/email/_bodyText", args=args )
			, htmlBody = renderView( view="/formbuilder/actions/email/_bodyHtml", args=args )
		};

		message.htmlBody = renderView( view="/emailTemplates/_adminHtmlLayout", args={ body=message.htmlBody } );

		return message;
	}

}