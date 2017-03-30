component {

	property name="emailTemplateService"      inject="emailTemplateService";
	property name="emailRecipientTypeService" inject="emailRecipientTypeService";

	public string function index( event, rc, prc, args={} ) {
		var recipientType = ( args.recipientType ?: "" );
		var templates = emailTemplateService.getTemplates(
			  custom        = IsTrue( args.custom ?: "" )
			, recipientType = recipientType
		);

		if ( !templates.recordcount ) {
			if ( !recipientType.len() ) {
				return '<p class="alert alert-warning">' & translateResource( "cms:emailcenter.no.templates.for.selection" ) & '</p>';
			} else {
				recipientType = emailRecipientTypeService.getRecipientTypeDetails( recipientType );
				recipientType = recipientType.title ?: "";

				return '<p class="alert alert-warning">' & translateResource( uri="cms:emailcenter.no.templates.for.selection.of.type", data=[ recipientType ] ) & '</p>';
			}
		}

		args.values = [ "" ];
		args.labels = [ "" ];

		for( var template in templates ) {
			args.values.append( template.id   );
			args.labels.append( template.name );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}
}