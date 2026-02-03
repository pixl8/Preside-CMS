component {

	public void function raiseError( required struct error ) {
		if ( ( arguments.error.type ?: "" ) == "test.e2e.error.handling" ) {
			content reset=true type="application/json";
			echo( '{"testpassed":true}' );
			abort;
		}
	}

}