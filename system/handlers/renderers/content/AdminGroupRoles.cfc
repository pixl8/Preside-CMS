component {

	private string function default( event, rc, prc, args={} ){
		var roles = ListToArray( args.data ?: "" );
		var output = "<dl>";

		for( var role in roles ) {
			output &= "<dt>" & translateResource( uri="roles:#role#.title" ) & "</dt>";
			output &= "<dd>" & translateResource( uri="roles:#role#.description" ) & "</dd>";
		}
		output &= "</dl>";

		return output;
	}

	private string function adminView( event, rc, prc, args={} ) {
		var roles = ListToArray( args.data ?: "" );
		var output = [];

		for( var role in roles ) {
			output.append( translateResource( uri="roles:#role#.title" ) );
		}

		return output.toList( ", " );
	}

}