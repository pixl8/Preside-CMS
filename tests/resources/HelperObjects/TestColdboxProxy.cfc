component output=false accessors=true {

	property name="log" default="";

	function onMissingMethod( missingMethodName, missingMethodArguments ) output=false {
		var log = getLog();

		if ( not IsStruct( log ) ) {
			log = {};
		}

		if ( not StructKeyExists( log, arguments.missingMethodName ) ) {
			log[ arguments.missingMethodName ] = [];
		}

		ArrayAppend( log[ arguments.missingMethodName ], arguments.missingMethodArguments );

		setLog( log );

		return "";
	}
}