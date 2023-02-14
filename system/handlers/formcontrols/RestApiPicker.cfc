component {
	property name="presideRestService" inject="presideRestService";

	public string function index( event, rc, prc, args={} ) {
		args.apis = presideRestService.listApis();
		args.authOnly = IsTrue( args.authOnly ?: "" );

		for( var i=args.apis.len(); i>0; i-- ) {
			if ( !Len( Trim( args.apis[ i ].authProvider ) ) ) {
				args.apis.deleteAt( i );
			}
		}

		return renderView( view="formcontrols/restApiPicker/index", args=args );
	}
}