/**
 * @feature admin
 */
component {

	private string function default( event, rc, prc, args={} ){
		var reference = args.data ?: "";

		return Len( reference ) ? reference : translateResource( "cms:preside-objects.default.field.no_value.title" );
	}

}