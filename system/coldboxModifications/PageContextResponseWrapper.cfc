component {

	function init( required any resp ) {
		variables.resp = arguments.resp;

		return this;
	}

	function setStatus( status, text="" ) {
		return variables.resp.setStatus( JavaCast( "int", arguments.status ) );
	}

	function onMissingMethod( missingMethodName, missingMethodArguments ) {
		return variables.resp[ missingMethodName ]( argumentCollection=missingMethodArguments );
	}

}