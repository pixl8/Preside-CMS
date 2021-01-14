component {

	public string function admindatatable( event, rc, prc, args={} ){
		if ( Len( args.data ?: "" ) ) {
			var ev = "";
			switch( args.record.kind ?: "" ) {
				case "filter":
					ev = "renderers.content.objectName.admindatatable"
				break;
				case "condition":
					ev = "renderers.content.rulesEngineContextName.default"
				break;
			}

			if ( Len( ev ) ) {
				return runEvent(
					  event = ev
					, private = true
					, prePostExempt = true
					, eventArguments = { args=args }
				);
			}
		}

		return args.data ?: "";
	}

	public string function default( event, rc, prc, args={} ){
		return args.data ?: "";
	}

}