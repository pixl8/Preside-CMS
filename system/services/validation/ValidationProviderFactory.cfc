component output="false" {

	public ValidationProvider function createProvider( required any sourceCfc ) output=false {
		var provider = new ValidationProvider( sourceCfc=arguments.sourceCfc );
		var meta     = GetMetaData( arguments.sourceCfc );
		var method   = "";
		var isValidator = "";

		param name="meta.validationProvider" default="false";
		if ( not IsBoolean( meta.validationProvider ) ) {
			meta.validationProvider = false;
		}

		if ( StructKeyExists( meta, "functions" ) ) {
			for( method in meta.functions ){
				param name="method.validator"        default="#meta.validationProvider#";
				param name="method.validatorName"    default="#method.name#";
				param name="method.validatorMessage" default="";
				param name="method.access"           default="public";

				isValidator = method.access eq "public";
				isValidator = isValidator and IsBoolean( method.validator ) and method.validator;
				isValidator = isValidator and Right( method.name, 3 ) neq "_js";

				if ( isValidator ) {
					provider.addValidator(
						  name           = method.validatorName
						, method         = method.name
						, params         = _extractCustomParams( method )
						, jsFunction     = _extractJsFunction( method.name, sourceCfc )
						, defaultMessage = method.validatorMessage
					);
				}
			}
		}

		return provider;
	}

// PRIVATE HELPERS
	private array function _extractCustomParams( required struct method ) output=false {
		param name="method.parameters" type="array" default=[];

		var customParams   = [];
		var param          = "";
		var standardParams = "fieldName,data,value";

		for( param in method.parameters ){
			if ( not listFindNoCase( standardParams, param.name ) ) {
				ArrayAppend( customParams, param );
			}
		}

		return customParams;
	}

	private string function _extractJsFunction( required string methodName, required any sourceCfc ) output=false {
		var jsMethod = arguments.methodName & "_js";
		var methods  = GetMetaData( arguments.sourceCfc ).functions;
		var method   = "";
		var result   = "";

		for( method in methods ) {
			if ( method.access eq "public" and method.name eq jsMethod ) {
				result = arguments.sourceCfc[ jsMethod ]();

				if ( not IsSimpleValue( result ) ) {
					throw( type="ValidationProvider.badJsReturnValue", message="A non-string value was returned from the javascript validator function, [#jsMethod#]. This method should return a string containing a javascript function." );
				}

				break;
			}
		}

		return result;
	}

}