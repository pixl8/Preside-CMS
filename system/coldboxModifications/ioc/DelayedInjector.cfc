component {

// CONSTRUCTOR
	public any function init(
		  required any    injector
		, required any    targetObject
		,          string name = ""
		,          string dsl  = ""
	) {
		var injectorArgs = { targetObject = arguments.targetObject };
		if ( Len( Trim( arguments.name ) ) ) {
			injectorArgs.name = arguments.name;
		} else {
			injectorArgs.dsl = arguments.dsl;
		}

		_setInjector( arguments.injector );
		_setInjectorArgs( injectorArgs )

		return this;
	}

// PUBLIC API METHODS
	public any function get() {
		var instance = _getInstance();
		if ( IsNull( instance ) ) {
			instance = _getInjector().getInstance( argumentCollection=_getInjectorArgs() );
			_setInstance( instance );
		}

		return instance;
	}

	public any function onMissingMethod( required string missingMethodName, struct missingmethodArguments={} ) {
		var instance = get();
		return instance[ arguments.missingMethodName ]( argumentCollection=arguments.missingMethodArguments );
	}

// GETTERS AND SETTERS
	private any function _getInjector() {
		return _injector;
	}
	private void function _setInjector( required any injector ) {
		_injector = arguments.injector;
	}

	private struct function _getInjectorArgs() {
		return _injectorArgs;
	}
	private void function _setInjectorArgs( required struct injectorArgs ) {
		_injectorArgs = arguments.injectorArgs;
	}

	private any function _getInstance() {
		return _instance ?: NullValue();
	}
	private void function _setInstance( required any instance ) {
		_instance = arguments.instance;
	}
}