/**
 * @feature presideForms
 */
component {

	private string function index( event, rc, prc, args={} ) {
		var relativeOperator = arguments.args.relativeOperator ?: "";

		if ( !isEmptyString( relativeOperator ) && isTrue( arguments.args.relativeToCurrentDate ?: "" ) ) {
			var offset = arguments.args.offset ?: "";

			switch ( relativeOperator ) {
				case "lt":
					var diff = val( offset ) ? val( -offset ) : -1;
					args.maxDate = dateAdd( 'd', diff, now() );
					break;

				case "lte":
					var diff = val( offset ) ? val( -offset ) : 0;
					args.maxDate = dateAdd( 'd', diff, now() );
					break;

				case "gt":
					var diff = val( offset ) ? val( offset ) : 1;
					args.minDate = dateAdd( 'd', diff, now() );
					break;

				case "gte":
					var diff = val( offset ) ? val( offset ) : 0;
					args.minDate = dateAdd( 'd', diff, now() );
					break;
			}
		}

		return renderView( view="formcontrols/datePicker/index", args=args );
	}

}
