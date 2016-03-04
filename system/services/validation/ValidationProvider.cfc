component output="false" {

	public any function init( required any sourceCfc ) output=false {
		_setSourceCfc( arguments.sourceCfc );
		_setValidators( {} );

		return this;
	}

	public array function listValidators() output=false {
		var validators = StructKeyArray( _getValidators() );

		ArraySort( validators, "textnocase" );

		return validators;
	}

	public void function addValidator( required string name, required string method, array params=[], string jsFunction="", string defaultMessage="" ) output=false {
		var validators = _getValidators();

		validators[ arguments.name ] = {
			  method         = arguments.method
			, params         = arguments.params
			, jsFunction     = arguments.jsFunction
			, defaultMessage = arguments.defaultMessage
		};
	}

	public boolean function validatorExists( required string name ) output=false {
		var validators = _getValidators();

		return StructKeyExists( validators, arguments.name );
	}

	public any function runValidator(
		  required string name
		,          string fieldName = ""
		,          any    value     = ""
		,          struct data      = {}
		,          struct params    = {}
	) output=false {

		var sourceCfc  = _getSourceCfc();
		var validators = _getValidators();
		var method     = "";
		var args       = {};
		var param      = "";

		if ( not validatorExists( arguments.name ) ) {
			throw(
				  type    = "ValidationProvider.missingValidator"
				, message = "The validator, [#arguments.name#], does not exist for this Validation Provider"
			);
		}

		method = validators[ arguments.name ].method;

		args.fieldName = arguments.fieldName;
		args.value     = arguments.value;
		args.data      = arguments.data;

		for( param in validators[ arguments.name ].params ){
			param name="param.required" default="false";
			param name="param.name"     default="__really_should_be_defined__";

			if ( IsBoolean( param.required ) and param.required and not StructKeyExists( arguments.params, param.name ) ) {
				throw(
					  type    = "ValidationProvider.missingValidatorParam"
					, message = "The required parameter, [#param.name#], for the [#arguments.name#] validator is missing. This should be defined in the validation rule for this field ([#arguments.fieldName#])"
				);
			}
		}

		for( param in arguments.params ){
			args[ param ] = arguments.params[ param ];
		}

		return sourceCfc[ method ]( argumentCollection = args );
	}

	public array function getValidatorParamValues( required string name, struct params={} ) output=false {
		var validators = _getValidators();
		var param      = "";
		var values     = [];

		if ( validatorExists( arguments.name ) ) {
			for( param in validators[ arguments.name ].params ){
				param name="param.name" default="__really_should_be_defined__";

				if ( StructKeyExists( arguments.params, param.name ) ) {
					ArrayAppend( values, arguments.params[ param.name ] );
				} else {
					param name="param.default" default="";

					ArrayAppend( values, param.default );
				}
			}
		}

		return values;
	}

	public string function getJsFunction( required string name ) output=false {
		if ( validatorExists( arguments.name ) ) {
			return _getValidators()[ arguments.name ].jsFunction;
		}

		return "";
	}

	public string function getDefaultMessage( required string name ) output=false {
		if ( validatorExists( arguments.name ) ) {
			return _getValidators()[ arguments.name ].defaultMessage;
		}

		return "";
	}

// GETTERS AND SETTERS
	private struct function _getValidators() output=false {
		return _validators;
	}
	private void function _setValidators( required struct validators ) output=false {
		_validators = arguments.validators;
	}

	private any function _getSourceCfc() output=false {
		return _sourceCfc;
	}
	private void function _setSourceCfc( required any sourceCfc ) output=false {
		_sourceCfc = arguments.sourceCfc;
	}
}