component output=false {

	property name="assetManagerService" inject="assetManagerService";

	public string function RichEditor( event, rc, prc, args={} ){
		if ( Len( Trim( args.dimensions ?: "" ) ) && ListLen( args.dimensions, "x" ) == 2 ) {
			var width  = Val( ListFirst( args.dimensions, "x" ) );
			var height = Val( ListLast( args.dimensions, "x" ) );

			if ( width && height ) {
				args.derivative = "#width#x#height#";

				assetManagerService.createAssetDerivativeWhenNotExists(
					  assetId         = ( args.id ?: "" )
					, derivativeName  = args.derivative
					, transformations = [ { method="resize", args={ width=width, height=height, maintainAspectRatio=true } } ]
				);
			}
		}

		return renderView( view="/renderers/asset/image/richEditor", args=args );
	}

}