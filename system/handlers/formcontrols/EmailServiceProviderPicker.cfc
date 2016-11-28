component {

	property name="emailServiceProviderService" inject="emailServiceProviderService";

	public string function index( event, rc, prc, args={} ) output=false {
		args.providers = emailServiceProviderService.listProviders();

		if ( IsTrue( args.addDefaultProvider ?: true ) ) {
			args.providers.prepend( {
				  id          = ""
				, title       = translateResource( "cms:emailcenter.default.email.service.provider" )
				, description = translateResource( "cms:emailcenter.default.email.service.provider.description" )
			});
		}

		return renderView( view="formcontrols/emailServiceProviderPicker/index", args=args );
	}
}