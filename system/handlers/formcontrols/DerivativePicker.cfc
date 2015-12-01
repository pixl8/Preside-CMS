component output=false {

	property name="assetManagerService"  inject="AssetManagerService";

	public string function index( event, rc, prc, args={} ) output=false {

		var derivatives = assetManagerService.listEditorDerivates();
		var args.labels = [];
		var args.values = [];
		var args.width  = [];
		var args.height = [];

		for( var derivative in derivatives.value ) {
		    args.values.append( derivative );
			args.labels.append( translateResource( uri="derivatives:#derivative#.title", defaultValue="derivatives:#derivative#.title" ) );
		}

		for( var transformation in derivatives.dimension ) {

			for( var dimension in transformation ){

				if ( dimension.args.keyExists( "width" ) ) {

					args.height.append( dimension.args.height );
			    	args.width.append( dimension.args.width );
				}
			}

		}

		return renderView( view="formcontrols/selectDerivatives/index", args=args );

	}
}