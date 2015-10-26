component acessors=true extends="preside.system.base.JsonRpc2Handler" {

// terminal controller (all methods come through here)
	function index( event, rc, prc ) {
		var method        = jsonRpc2Plugin.getRequestMethod();
		var targetEvent   = "admin.devtools.terminalCommands.#method#.index";

		if ( method == "listMethods" && StructKeyExists( jsonRpc2Plugin.getRequestParams(), "systemcall" ) ) {
			return _listMethods( argumentCollection = arguments );
		}

		if ( !_isMethodEnabled( method ) || !getController().handlerExists( targetEvent ) ) {
			jsonRpc2Plugin.error( jsonRpc2Plugin.ERROR_CODES.METHOD_NOT_FOUND, "Method named [#method#] not found" );
			return;
		}

		return runEvent(
			  event          = targetEvent
			, prePostExempt  = true
			, private        = true
			, eventArguments = { terminalParams = jsonRpc2Plugin.getRequestParams() }
		);
	}

// helpers
	private function _listMethods( event, rc, prc ) {
		if ( !IsSimpleValue( _methods ?: "" ) ) {
			return _methods;
		}

		_methods = {};

		var handlerSvc = getController().getHandlerService();
		var handlers   = handlerSvc.listHandlers( "admin.devtools.terminalCommands." );

		for( var handler in handlers ){
			try {
				var handlerMeta = getComponentMetaData( handlerSvc.getRegisteredHandler( handler & ".index" ).getRunnable() );
				var methodName  = LCase( ListLast( handlerMeta.name ?: "unknown", "." ) );

				if ( _isMethodEnabled( methodName ) ) {
					_methods[ methodName ] = handlerMeta.hint ?: "";
				}

			} catch ( any e ) {}
		}

		return _methods;
	}

	private function _isMethodEnabled( required string method ) {
		var targetFeature = "devtools.#method#";

		return !isFeatureDefined( targetFeature ) || isFeatureEnabled( targetFeature );
	}



}