/**
 * Facilitates the reading of rules engine expressions from source ColdBox handler directories.
 * See [[rules-engine]] for more details.
 *
 * @autodoc
 * @singleton
 *
 */
component {

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
				expressions[ baseId & "." & func.name ] = {};
			}
		}

		return expressions;
	}


}