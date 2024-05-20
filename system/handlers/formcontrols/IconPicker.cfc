/**
 * @feature presideForms
 */
component {

	property name="fullIconSet" inject="coldbox:setting:formControls.iconPicker.icons";

	private string function admin( event, rc, prc, args={} ) {
		args.icons = args.icons ?: [];

		if ( IsSimpleValue( args.icons ) ) {
			args.icons = ListToArray( args.icons );
		}

		if ( !ArrayLen( args.icons ) ) {
			args.icons = fullIconSet;
		}

		return renderView( view="formcontrols/iconPicker/index", args=args );
	}

}