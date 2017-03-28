component {

	property name="emailServiceProviderService" inject="emailServiceProviderService";

	public string function index( event, rc, prc, args={} ) output=false {
		args.providers = emailServiceProviderService.listProviders( includeDisabled=IsTrue( args.includeDisabledProviders ?: "" ) );

		if ( IsTrue( args.addDefaultProvider ?: true ) ) {
			args.providers.prepend( {
				  id          = ""
				, title       = translateResource( "cms:emailcenter.default.email.service.provider" )
				, description = translateResource( "cms:emailcenter.default.email.service.provider.description" )
			});
		}

		if ( IsTrue( args.multiple ?: "" ) ) {
			args.values = [];
			args.labels = [];

			for( var provider in args.providers ) {
				args.values.append( provider.id );
				args.labels.append( provider.title );
			}

			return renderView( view="formcontrols/select/index", args=args );
		}

		return renderView( view="formcontrols/emailServiceProviderPicker/index", args=args );
	}
}