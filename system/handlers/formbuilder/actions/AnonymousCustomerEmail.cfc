component {

	property name="emailService"       inject="emailService";
	property name="formBuilderService" inject="formBuilderService";

	private void function onSubmit( event, rc, prc, args={} ) {
		if ( !isLoggedIn() ) {
			var template  = Trim( args.configuration.emailTemplate ?: "" );
			var fieldItem = formBuilderService.getFormItem( Trim( args.configuration.emailField ?: "" ) );
			var field     = fieldItem.configuration.name ?: "";
			var data      = {};

			try {
				data = DeserializeJson( args.submissionData.submitted_data ?: "" );
			} catch( any e ) {}


			var address = Trim( data[ field ] ?: "" );

			if ( template.len() && address.len() ) {
				emailService.send(
					  template    = template
					, recipientId = address
					, to          = [ address ]
				);
			}
		}
	}

	private string function renderAdminPlaceholder( event, rc, prc, args={} ) {
		var template = args.configuration.emailTemplate ?: "";

		return '<i class="fa fa-fw fa-envelope"></i> ' & translateResource(
			  uri  = "formbuilder.actions.anonymousCustomerEmail:admin.placeholder"
			, data = [ "<strong>" & renderLabel( "email_template", template ) & "</strong>" ]
		);
	}
}