component {
	property name="simpleColourPickerService" inject="SimpleColourPickerService";

	public string function index( event, rc, prc, args={} ) {
		if ( structKeyExists( args, "colours" ) ) {
			args.colours = listToArray( args.colours, "|" );
		} else {
			args.append( simpleColourPickerService.getPalette( args.palette ?: "web64" ), false );
		}
		args.currentValue = args.savedData[ args.name ] ?: ( args.defaultValue ?: "" );
		args.colourFormat = args.colourFormat           ?: "hex";
		args.colours      = simpleColourPickerService.convertColours( args.colours, args.colourFormat );

		return renderView( view="/formcontrols/simpleColourPicker/index", args=args );
	}
}