component implements="coldbox.system.ioc.dsl.IDSLBuilder" {

	public any function init( required any injector ) {
		_setInjector( arguments.injector );

		return this;
	}

	public any function process( required any definition, any targetObject ) {
		var dsl = ListRest( arguments.definition.dsl ?: "", ":" );

		if ( ListLen( dsl, ":" ) < 2 ) {
			throw( type="preside.invalid.dsl", message="The injection dsl, [featureInjector:#dsl#], is invalid. Use the format: [featureInjector:{featureName}:{dependencyIdOrDsl}]" );
		}

		var feature = ListFirst( dsl, ":" );
		var service = ListRest( dsl, ":" );


		if ( _getInjector().getInstance( "featureService" ).isFeatureEnabled( feature ) ) {
			return _getInjector().getInstance( dsl=service );
		}

		return "";
	}


// GETTERS AND SETTERS
	private any function _getInjector() {
		return _injector;
	}
	private void function _setInjector( required any injector ) {
		_injector = arguments.injector;
	}

}