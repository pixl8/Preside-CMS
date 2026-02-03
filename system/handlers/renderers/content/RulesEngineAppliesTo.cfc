/**
 * @feature rulesEngine
 */
component {

	public string function admindatatable( event, rc, prc, args={} ){
		return _renderData( argumentCollection=arguments, data=( args.data ?: "" ), kind=( args.record.kind ?: "" ) );
	}

	public string function picker( event, rc, prc, args={} ){
		return _renderData( argumentCollection=arguments, data=( args.data ?: "" ), kind=( args.kind ?: "" ) );
	}

	public string function default( event, rc, prc, args={} ){
		return args.data ?: "";
	}

	private string function _renderData( string data="", string kind="" ) {
		if ( !isEmptyString( arguments.data ) ) {
			var ev = "";
			switch( arguments.kind ) {
				case "filter":
					ev = "renderers.content.objectName.admindatatable";
				break;
				case "condition":
					ev = "renderers.content.rulesEngineContextName.default";
				break;
			}

			if ( Len( ev ) ) {
				return runEvent(
					  event          = ev
					, private        = true
					, prePostExempt  = true
					, eventArguments = { args=arguments.args }
				);
			}
		}

		return args.data ?: "";
	}

}