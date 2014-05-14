component output=false {

	property name="assetManagerService" inject="assetManagerService";

	public string function RichEditor( event, rc, prc, viewletArgs={} ){
		if ( Len( Trim( viewletArgs.dimensions ?: "" ) ) && ListLen( viewletArgs.dimensions, "x" ) == 2 ) {
			var width  = Val( ListFirst( viewletArgs.dimensions, "x" ) );
			var height = Val( ListLast( viewletArgs.dimensions, "x" ) );

			if ( width && height ) {
				viewletArgs.derivative = "#width#x#height#";

				assetManagerService.createAssetDerivativeWhenNotExists(
					  assetId         = ( viewletArgs.id ?: "" )
					, derivativeName  = viewletArgs.derivative
					, transformations = [ { method="resize", args={ width=width, height=height, maintainAspectRatio=true } } ]
				);
			}
		}

		return renderView( view="/renderers/asset/image/richEditor", args=viewletArgs );
	}

}