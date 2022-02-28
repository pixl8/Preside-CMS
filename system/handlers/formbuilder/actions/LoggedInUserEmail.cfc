component {

	property name="emailService"       inject="emailService";
	property name="formBuilderService" inject="formBuilderService";

	private void function onSubmit( event, rc, prc, args={} ) {
		if ( isLoggedIn() ) {
			var template        = Trim( args.configuration.emailTemplate ?: "" );
			var formBuilderForm = formBuilderService.getForm( args.formId ?: "" );
			var emailArgs       = { form_name=formBuilderForm.name ?: "" };

			if ( template.len() ) {
				emailService.send(
					  template    = template
					, recipientId = getLoggedInUserId()
					, args        = emailArgs
				);
			}
		}
	}

	private string function renderAdminPlaceholder( event, rc, prc, args={} ) {
		var template = args.configuration.emailTemplate ?: "";

		return '<i class="fa fa-fw fa-envelope"></i> ' & translateResource(
			  uri  = "formbuilder.actions.loggedInUserEmail:admin.placeholder"
			, data = [ "<strong>" & renderLabel( "email_template", template ) & "</strong>" ]
		);
	}
}