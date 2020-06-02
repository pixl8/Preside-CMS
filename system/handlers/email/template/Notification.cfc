component {

	property name="notificationService" inject="notificationService";

	private struct function prepareParameters(
		  required string topic
		, required struct data
		,          string notificationId = ""
	) {
		var params = {};

		if ( Len( Trim( arguments.notificationId ) ) ) {
			params.admin_link = event.buildAdminLink(
				  linkto      = "notifications.view"
				, querystring = "id=" & arguments.notificationId
			);
		} else {
			params.admin_link = "";
		}

		params.notification_body = {
			  text = notificationService.renderNotification( arguments.topic, arguments.data, "emailText" )
			, html = notificationService.renderNotification( arguments.topic, arguments.data, "emailHtml" )
		};
		params.notification_subject = Trim( notificationService.renderNotification( arguments.topic, arguments.data, "emailSubject" ) );

		if ( !params.notification_subject.len() ) {
			params.notification_subject = "Preside: You have received a notification from the CMS";
		}

		return params;
	}

	private struct function getPreviewParameters() {
		return {
			  admin_link           = event.getBaseUrl() & "/dummy/notification/url/"
			, notification_body    = { text="This is a dummy notification.", html="<p>This is a dummy notification.</p>" }
			, notification_subject = "Something happened"
		};
	}

	private string function defaultSubject() {
		return "${notification_subject}";
	}

	private string function defaultHtmlBody() {
		return renderView( view="/email/template/notification/defaultHtmlBody" );
	}

	private string function defaultTextBody() {
		return renderView( view="/email/template/notification/defaultTextBody" );
	}


}