component {
	property name="storageLocationDao" inject="presidecms:object:asset_storage_location";

	public string function index( event, rc, prc, args={} ) {
		var locations = storageLocationDao.selectData( selectFields=[ "id", "name" ], orderBy="name" );

		args.values    = [ "" ];
		args.labels    = [ translateResource( "cms:assetmanager.storagelocationpicker.inherit.option" ) ];

		if ( locations.recordCount ) {
			args.values.append( ValueArray( locations.id   ), true );
			args.labels.append( ValueArray( locations.name ), true );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}
}