component {

	private string function adminDatatable( event, rc, prc, args={} ){
		var scope = args.data ?: "";

		if ( !Len( scope ) ) {
			scope = "global";
		}

		return renderContent(
			  renderer = "enumLabel"
			, data     = scope
			, context  = "adminDatatable"
			, args     = args
		);
	}

	private string function adminView( event, rc, prc, args={} ){
		var scope = args.data ?: "";

		if ( !Len( scope ) ) {
			scope = "global";
		}

		return renderContent(
			  renderer = "enumLabel"
			, data     = scope
			, context  = "adminView"
			, args     = args
		);
	}

}