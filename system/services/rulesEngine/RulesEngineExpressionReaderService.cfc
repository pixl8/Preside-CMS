/**
 * Facilitates the reading of rules engine expressions from source ColdBox handler directories.
 * See [[rules-engine]] for more details.
 *
 * @autodoc
 * @singleton
 *
 */
component {

	variables._booleanVarietyMappings = {
		  _is   = "isIsNot"
		, _has  = "hasHasNot"
		, _was  = "wasWasNot"
		, _will = "willWillNot"
	};

	/**
	 * Reads the configured rules engine expressions from the given handler CFC file.
	 * Returns a struct who's keys are IDs of expressions and who's values are the
	 * detailed configuration of the expression as defined in the handler CFC actions
	 *
	 * @autodoc
	 * @componentPath.hint Full mapped dotted path to the CFC, e.g. app.handlers.rules.expressions.myExpression
	 * @rootPath.hint      Root path of directory containing expressions, e.g. app.handlers.rules.expressions
	 */
	public struct function getExpressionsFromCfc( required string componentPath, required string rootPath ) {
		var meta        = getComponentMetadata( arguments.componentPath );
		var functions   = meta.functions ?: [];
		var baseId      = arguments.componentPath.replaceNoCase( rootPath, "" ).reReplace( "^\.", "" );
		var expressions = {};

		for( var func in functions ) {
			if ( IsBoolean( func.expression ?: "" ) && func.expression ) {
				expressions[ baseId & "." & func.name ] = {
					  contexts = ListToArray( func.expressionContexts ?: func.name )
					, fields   = getExpressionFieldsFromFunctionDefinition( func )
				};
			}
		}

		return expressions;
	}


	/**
	 * Reads the function metadata and returns a struct of expression
	 * field configurations
	 *
	 * @autodoc
	 * @functionMeta.hint Metadata about the function
	 *
	 */
	public struct function getExpressionFieldsFromFunctionDefinition( required any functionMeta ) {
		var params                 = functionMeta.parameters ?: [];
		var standardParamsToIgnore = [ "event", "rc", "prc", "args", "payload", "context" ];
		var fields                 = {};

		for( var param in params ) {
			if ( !standardParamsToIgnore.findNoCase( param.name ) ) {
				fields[ param.name ] = getFieldDefinition( param );
			}
		}

		return fields;
	}

	/**
	 * Reads function argument meta data and returns a rules
	 * engine expression field configuration.
	 *
	 * @autodoc
	 * @functionArgumentMeta.hint Metadata for the function argument
	 */
	public struct function getFieldDefinition( required struct functionArgumentMeta ) {
		var argName            = functionArgumentMeta.name ?: "";
		var argAttribsToIgnore = [ "name", "type", "hint" ];
		var definition         = {};

		switch( argName ) {
			case "_is" :
			case "_has" :
			case "_was" :
			case "_will" :
				definition.fieldType = "boolean";
				definition.variety        = _booleanVarietyMappings[ argName ];
			break;

			case "_all" :
			case "_any" :
				definition.fieldType = "scope";
			break;
		}

		for( var attribName in functionArgumentMeta ) {
			if ( !argAttribsToIgnore.findNoCase( attribName ) ) {
				definition[ attribName ] = functionArgumentMeta[ attribName ];
			}
		}

		return definition;
	}

}