component {

	private struct function prepareParameters(
		  required struct submissionData
		, required struct configuration
	) {
		var link      = event.buildAdminLink( linkto="formbuilder.submissions", queryString="id=" & ( arguments.submissionData.form ?: "" ) );
		var linkTitle = translateResource( "formbuilder:email.notificatio.admin.link.text" );

		return {
			  admin_link = {
			  	  html = '<a href="#link#">#linkTitle#</a>'
			  	, text = link
			  }
			, submission_preview = {
				  html = renderView( view="/email/template/formbuilderSubmissionNotification/_submissionHtml", args=arguments )
				, text = renderView( view="/email/template/formbuilderSubmissionNotification/_submissiontext", args=arguments )
			  }
			, notification_subject = arguments.configuration.subject ?: "Form builder submission"
		};
	}

	private struct function getPreviewParameters() {
		var link      = event.getBaseUrl() & "/dummy/formsubmission/url/"
		var linkTitle = translateResource( "formbuilder:email.notificatio.admin.link.text" );
		var args      = { submissionData={
			  submitted_by    = ""
			, datecreated     = "1980-12-09 03:15:22"
			, form_instance   = "Homepage"
			, ip_address      = "127.0.0.1"
			, user_agent      = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:49.0) Gecko/20100101 Firefox/49.0"
			, submitted_data  = ""
		} } ;

		return {
			  admin_link = {
			  	  html = '<a href="#link#">#linkTitle#</a>'
			  	, text = link
			  }
			, submission_preview = {
				  html = renderView( view="/email/template/formbuilderSubmissionNotification/_submissionHtml", args=args )
				, text = renderView( view="/email/template/formbuilderSubmissionNotification/_submissiontext", args=args )
			  }
		};
	}

	private string function defaultSubject() {
		return "${notification_subject}";
	}

	private string function defaultHtmlBody() {
		return renderView( view="/email/template/formbuilderSubmissionNotification/defaultHtmlBody" );
	}

	private string function defaultTextBody() {
		return renderView( view="/email/template/formbuilderSubmissionNotification/defaultTextBody" );
	}


}