component output=false {

	property name="notificationService" inject="notificationService";

	private struct function prepareMessage( event, rc, prc, args={} ) output=false {
		var topic = args.topic ?: "";
		var data  = args.data  ?: {};


		if ( Len( Trim( args.notificationId ?: "" ) ) ) {
			args.notificationLink = event.buildAdminLink(
				  linkto      = "notifications.view"
				, querystring = "id=" & ( args.notificationId ?: "" )
			);
		}

		args.notificationBodyHtml = notificationService.renderNotification( topic, data, "emailHtml" );
		args.notificationBodyText = notificationService.renderNotification( topic, data, "emailText" );

		var message = {
			  subject  = Trim( notificationService.renderNotification( topic, data, "emailSubject" ) )
			, textBody = renderView( view="/emailTemplates/notification/text", args=args )
			, htmlBody = renderView( view="/emailTemplates/notification/html", args=args )
		};

		if ( !Len( message.subject ?: "" ) ) {
			message.subject = "PresideCMS: You have received a notification from the CMS";
		}

		message.htmlBody = renderView( view="/emailTemplates/_adminHtmlLayout", args={ body=message.htmlBody, subject=message.subject } );

		return message;
	}

}