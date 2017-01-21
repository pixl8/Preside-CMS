component {

	property name="emailTemplateService" inject="emailTemplateService";

	public string function index( event, rc, prc, args={} ) {
		var templates = emailTemplateService.getTemplates(
			  custom        = IsTrue( args.custom ?: "" )
			, recipientType = ( args.recipientType ?: "" )
		);

		if ( !templates.recordcount ) {
			return "";
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