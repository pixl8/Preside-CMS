component output=false {

	property name="assetTypes" inject="coldbox:setting:assetManager.types";

	public string function index( event, rc, prc, args={} ) output=false {
		var types = [];
		args.values = [];
		args.labels = [];

		for( var assetTypeGroup in assetTypes ){
			types.append( {
				  value = assetTypeGroup
				, label = translateResource( "filetypes:#assetTypeGroup#.picker.label" )
			} );

			for( var type in assetTypes[ assetTypeGroup ] ){
				types.append( {
					  value = type
					, label = translateResource( "filetypes:#type#.picker.label" )
				} );
			}
		}

		types.sort( function( a, b ){
			return a.label > b.label ? 1 : -1;
		} );

		for( var type in types ){
			args.labels.append( type.label );
			args.values.append( type.value );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}
}