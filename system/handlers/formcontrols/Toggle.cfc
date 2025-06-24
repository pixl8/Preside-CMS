component {
	public string function index( event, rc, prc, args={} ) {
		event.include( "/js/admin/specific/toggleControl/" );

		var toggleType = args.toggleType ?: "checkbox";

		if ( toggleType == "radio" ) {
			if ( isEmptyString( args.defaultValue ?: "" ) ) {
				args.defaultValue = 0;
			}

			if ( isEmptyString( args.values ?: "" ) ) {
				args.values = "0,1";

				if ( isBoolean( args.defaultValue ) ) {
					args.defaultValue = args.defaultValue ? 1 : 0;
				}
			}
		}

		args.class = Trim( args.class ?: "" );

		args.class &= ( isEmptyString( args.toggleClass ?: "" ) ? " toggle-fields" : args.toggleClass );

		return renderView( view="/formcontrols/toggle/_#toggleType#", args=args );
	}
}