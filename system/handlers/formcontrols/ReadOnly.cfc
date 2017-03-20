component {

	property name="presideObjectService" inject="presideObjectService";

	public string function index( event, rc, prc, args={} ) {
		var renderer = args.renderer ?: "";
		var type     = presideObjectService.getObjectPropertyAttribute( args.sourceObject, args.name, "type" );

		if ( listFindNoCase( "date,datetime", type ) ) {
			args.renderer = type;
		}

		if ( renderer == "none" ) {
			args.renderer = "";
		}

		return renderView( view="formcontrols/readOnly/index", args=args );
	}
}
