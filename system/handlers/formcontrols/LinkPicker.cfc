component output=false {

	public string function index( event, rc, prc, args={} ) output=false {
		args.append( _loadLinks( argumentCollection=arguments ) );

		args.quickAdd            = true;
		args.quickEdit           = true;

		args.quickAddUrl         = event.buildAdminLink( linkTo="LinkPicker.quickAdd" );
		args.quickEditUrl        = event.buildAdminLink( linkTo="LinkPicker.quickEdit" );

		args.quickAddModalTitle  = translateResource( "cms:linkpicker.quickadd.title" );
		args.quickEditModalTitle = translateResource( "cms:linkpicker.quickedit.title" );
		args.searchable          = false;


		return renderView( view="formcontrols/objectPicker/index", args=args );
	}


// private helpers
	private struct function _loadLinks( event, rc, prc, args={} ) output=false {
		var values  = event.getValue( name=( args.name ?: "" ), defaultValue="" );
		var records = QueryNew( 'id,label' );

		if ( not IsSimpleValue( values ) ) {
			values = "";
		}

		values = ListToArray( values );
		for( var value in values ){
			var deserialized = UrlDecode( value );
			if ( IsJson( deserialized ) ) {
				deserialized = DeserializeJson( deserialized );
				QueryAddRow( records );
				QuerySetCell( records, "id"   , value );
				QuerySetCell( records, "label", deserialized.title ?: "No title" );
			}
		}

		return { records = records };
	}
}