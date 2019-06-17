/**
 * Facilitates the reading of rules engine expressions from source ColdBox handler directories.
 * See [[rules-engine]] for more details.
 *
 * @autodoc
 * @singleton
 * @presideService
 */
component displayName="RulesEngine Expression Reader Service" {

	variables._booleanVarietyMappings = {
		  _is       = "isIsNot"
		, _has      = "hasHasNot"
		, _possesses = "hasDoesNotHave"
		, _did      = "didDidNot"
		, _was      = "wasWasNot"
		, _are      = "areAreNot"
		, _does     = "doesDoesNot"
		, _will     = "willWillNot"
		, _ever     = "everNever"
		, _all      = "allAny"
	};

// CONSTRUCTOR
	/**
	 * @contextService.inject rulesEngineContextService
	 *
	 */
	public any function init( required any contextService ) {
		_setContextService( arguments.contextService );

		return this;
	}


// PUBLIC API
	/**
	 * Reads all the expressions from an array of directories potentially containing handler CFC files
	 * and returns a structure whose keys are the IDs of expressions and whose values are the
	 * detailed configuration of the expression as defined in the handler CFC actions
	 *
	 * @autodoc
	 * @directories array of mapped path to the directory, e.g. [ "/preside/system/handlers/rules/expressions", "/app/handlers/rules/expressions" ]
	 */
	public struct function getExpressionsFromDirectories( required array directories ) {
		var expressions = {};

		for( var dir in arguments.directories ) {
			expressions.append( getExpressionsFromDirectory( dir ) );
		}

		return expressions;
	}

	/**
	 * Reads all the expressions from a directory of handler CFC files
	 * and returns a structure whose keys are the IDs of expressions and whose values are the
	 * detailed configuration of the expression as defined in the handler CFC actions
	 *
	 * @autodoc
	 * @directory mapped path to the directory, e.g. /app/handlers/rules/expressions
	 */
	public struct function getExpressionsFromDirectory( required string directory ) {
		var dottedDirPath   = arguments.directory.reReplace( "[\\/]", ".", "all" ).reReplace( "^\.", "" ).reReplace( "\.$", "" );
		var expandedDirPath = ExpandPath( arguments.directory );
		var handlerCfcs     = DirectoryList( expandedDirPath, true, "path", "*.cfc" );
		var expressions     = {};

		for( var handlerCfc in handlerCfcs ){
			var relativePath       = handlerCfc.replace( expandedDirPath, "" );
			var dottedRelativePath = relativePath.reReplace( "[\\/]", ".", "all" ).reReplace( "^\.", "" ).reReplace( "\.cfc$", "" );
			var dottedCfcPath         = dottedDirPath & "." & dottedRelativePath;

			expressions.append( getExpressionsFromCfc(
				  componentPath = dottedCfcPath
				, rootPath      = dottedDirPath
			) );
		}

		return expressions;
	}

	/**
	 * Reads the configured rules engine expressions from the given handler CFC file.
	 * Returns a struct whose keys are IDs of expressions and whose values are the
	 * detailed configuration of the expression as defined in the handler CFC actions
	 *
	 * @autodoc
	 * @componentPath.hint Full mapped dotted path to the CFC, e.g. app.handlers.rules.expressions.myExpression
	 * @rootPath.hint      Root path of directory containing expressions, e.g. app.handlers.rules.expressions
	 */
	public struct function getExpressionsFromCfc( required string componentPath, required string rootPath ) {
		var meta     = getComponentMetadata( arguments.componentPath );
		var feature  = meta.feature ?: "";
		var category = meta.expressionCategory ?: "default";
		var contexts = ListToArray( meta.expressionContexts ?: "global" );
		var contextsEnabled = false;
		var contextService = _getContextService();

		if ( Len( Trim( feature ) ) && !$isFeatureEnabled( feature ) ) {
			return {};
		}

		for( var context in contexts ) {
			contextsEnabled = contextService.contextExists( context );
			if ( contextsEnabled ) {
				break;
			}
		}

		if ( !contextsEnabled ) {
			return {};
		}

		var functions     = meta.functions ?: [];
		var baseId        = arguments.componentPath.replaceNoCase( rootPath, "" ).reReplace( "^\.", "" );
		var filterObjects = [];
		var expressions   = {};

		for( var func in functions ) {
			if ( func.name == "evaluateExpression" ) {
				expressions[ baseId ] = {
					  contexts              = _getContextService().expandContexts( ListToArray( meta.expressionContexts ?: "global" ) )
					, fields                = getExpressionFieldsFromFunctionDefinition( func )
					, filterObjects         = filterObjects
					, category              = category
					, expressionHandler     = "rules.expressions.#baseId#.evaluateExpression"
					, filterHandler         = filterObjects.len() ? "rules.expressions.#baseId#.prepareFilters" : ""
					, labelHandler          = "rules.expressions.#baseId#.getLabel"
					, textHandler           = "rules.expressions.#baseId#.getText"
					, expressionHandlerArgs = {}
					, filterHandlerArgs     = {}
					, labelHandlerArgs      = {}
					, textHandlerArgs       = {}
				};

			} else if ( func.name == "prepareFilters" ) {
				filterObjects = ListToArray( func.objects ?: "" );
				if ( StructKeyExists( expressions, baseId ) ) {
					expressions[ baseId ].filterObjects = filterObjects;
					expressions[ baseId ].filterHandler = "rules.expressions.#baseId#.prepareFilters";
					break;
				}
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
			case "_is":
			case "_has":
			case "_possesses":
			case "_did":
			case "_was":
			case "_will":
			case "_are":
			case "_ever":
			case "_all":
				definition.fieldType = "boolean";
				definition.variety   = _booleanVarietyMappings[ argName ];
			break;

			case "_stringOperator":
			case "_dateOperator":
			case "_numericOperator":
			case "_periodOperator":
				definition.fieldType = "operator";
				definition.variety   = argName.reReplaceNoCase( "^_(.*)Operator$", "\1" );
			break;

			case "_time":
			case "_pastTime":
			case "_futureTime":
				definition.fieldType  = "timePeriod";
				definition.futureOnly = ( argName == "_futureTime" );
				definition.pastOnly   = ( argName == "_pastTime" );
				definition.default    = "";
			break;
		}

		for( var attribName in functionArgumentMeta ) {
			if ( !argAttribsToIgnore.findNoCase( attribName ) ) {
				if ( attribName == "default" && functionArgumentMeta[ attribName ] == "[runtime expression]" ) {
					definition[ attribName ] = "";
				} else {
					definition[ attribName ] = functionArgumentMeta[ attribName ];

				}
			}
		}

		if ( !Len( Trim( definition.fieldType ?: "" ) ) ) {
			definition.fieldType = getDefaultFieldTypeForArgumentType( functionArgumentMeta.type ?: "any" );
		}

		return definition;
	}

	/**
	 * Returns a default expression field type for a given
	 * argument type. e.g. 'numeric' = 'number', 'string' = 'text', etc.
	 *
	 * @autodoc
	 * @argumentType.hint Type of the argument
	 */
	public string function getDefaultFieldTypeForArgumentType( required string argumentType ) {

		switch( arguments.argumentType ) {
			case "numeric":
				return "number";
			case "date":
			case "boolean":
				return arguments.argumentType;
		}

		return "text";
	}

// GETTERS AND SETTERS
	private any function _getContextService() {
		return _contextService;
	}
	private void function _setContextService( required any contextService ) {
		_contextService = arguments.contextService;
	}

}