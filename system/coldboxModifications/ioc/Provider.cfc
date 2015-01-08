component output=false {

// CONSTRUCTOR
	public any function init(
		  required any    injector
		, required any    targetObject
		,          string name = ""
		,          string dsl  = ""
	) output=false {
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
	public any function get() output=false {
		return _getInjector().getInstance( argumentCollection=_getInjectorArgs() );
	}

	public any function onMissingMethod( required string missingMethodName, struct missingmethodArguments={} ) output=false {
		var instance = get();
		return instance[ arguments.missingMethodName ]( argumentCollection=arguments.missingMethodArguments );
	}

// GETTERS AND SETTERS
	private any function _getInjector() output=false {
		return _injector;
	}
	private void function _setInjector( required any injector ) output=false {
		_injector = arguments.injector;
	}

	private struct function _getInjectorArgs() output=false {
		return _injectorArgs;
	}
	private void function _setInjectorArgs( required struct injectorArgs ) output=false {
		_injectorArgs = arguments.injectorArgs;
	}
}