component implements="coldbox.system.ioc.dsl.IDSLBuilder" output=false {

	public any function init( required any injector ) output=false {
		_setInjector( arguments.injector );

		return this;
	}

	public any function process( required any definition, any targetObject ) output=false {
		var thisType    = arguments.definition.dsl;
		var thisTypeLen = ListLen( thisType, ":" );
		var injectorDsl = "";
		var args        = {};

		switch( thisTypeLen ){
			case 1: { injectorDsl = arguments.definition.name; break; }
			case 2: { injectorDsl = getToken( thisType, 2, ":" ); break; }
			default : {
				injectorDsl = replaceNoCase( thisType, "delayedInjection:", "" );
			}
		}

		args = {
			  injector     = _getInjector()
			, targetObject = arguments.targetObject
		};

		if ( _getInjector().containsInstance( injectorDsl ) ) {
			args.name = injectorDsl;
		} else {
			args.dsl = injectorDsl;
		}

		return CreateObject( "component", "preside.system.coldboxModifications.ioc.DelayedInjector" ).init( argumentCollection=args );
	}

// GETTERS AND SETTERS
	private any function _getInjector() output=false {
		return _injector;
	}
	private void function _setInjector( required any injector ) output=false {
		_injector = arguments.injector;
	}

}