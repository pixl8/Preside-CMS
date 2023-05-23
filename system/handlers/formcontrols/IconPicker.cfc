component {

	private string function admin( event, rc, prc, args={} ) {
		args.icons = args.icons ?: [];

		if ( IsSimpleValue( args.icons ) ) {
			args.icons = ListToArray( args.icons );
		}

		if ( !ArrayLen( args.icons ) ) {
			args.icons = ListToArray( getSetting( name="formControls.iconPicker.icons", defaultValue="" ) );
		}

		return renderView( view="formcontrols/iconPicker/index", args=args );
	}

}