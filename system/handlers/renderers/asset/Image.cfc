component {

	property name="assetManagerService" inject="assetManagerService";

	public string function RichEditor( event, rc, prc, args={} ){
		if ( Len( Trim( args.dimensions ?: "" ) ) && ListLen( args.dimensions, "x" ) == 2 ) {
			var width   = Val( ListFirst( args.dimensions, "x" ) );
			var height  = Val( ListLast( args.dimensions, "x" ) );
			var transformArgs = { width=width, height=height, maintainAspectRatio=true };

			if ( width && height ) {
				args.derivative = "#width#x#height#";

				if ( Len( Trim( args.quality ?: "" ) ) ) {
					args.derivative &= "-#args.quality#";
					transformArgs.quality = args.quality;
				}

				try {
					assetManagerService.createAssetDerivativeWhenNotExists(
						  assetId         = ( args.id ?: "" )
						, derivativeName  = args.derivative
						, transformations = [ { method="resize", args=transformArgs } ]
					);
				} catch( any e ) {
					logError ( e );
				}
			}
		}

		return renderView( view="/renderers/asset/image/richEditor", args=args );
	}

}