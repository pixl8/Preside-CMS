component {

	property name="emailService" inject="emailService";

	private void function onSubmit( event, rc, prc, args={} ) {
		if ( isLoggedIn() ) {
			var template  = Trim( args.configuration.emailTemplate ?: "" );

			if ( template.len() ) {
				emailService.send(
					  template    = template
					, recipientId = getLoggedInUserId()
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