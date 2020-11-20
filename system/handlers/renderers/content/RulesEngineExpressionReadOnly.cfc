component {

	property name="expressionService" inject="rulesEngineExpressionService";
	property name="fieldTypeService"  inject="RulesEngineFieldTypeService";

	private string function default( event, rc, prc, args={} ){
		var expressionId     = args.expression   ?: "";
		var expressionFields = args.fields       ?: {};
		var ruleContext      = args.ruleContext  ?: "";
		var filterObject     = args.filterObject ?: "";

		try {
			var expression = expressionService.getExpression(
				  expressionId = LCase( expressionId )
				, context      = ruleContext
				, objectName   = filterObject
			);
			var rendered = expression.text;

			for( var fieldName in expressionFields ) {
				var renderedField = fieldTypeService.renderConfiguredField(
					  fieldType          = expression.fields[ fieldName ].fieldType ?: "text"
					, value              = expressionFields[ fieldName ]
					, fieldConfiguration = expression.fields[ fieldName ] ?: {}
				);
				var fieldClass = fieldName.startsWith( "_" ) ? "rules-engine-expression-system-value" : "rules-engine-expression-value";

				rendered = replace( rendered, "{#fieldName#}", '<span class="#fieldClass#">#renderedField#</span>' );
			}
		} catch( preside.rule.expression.not.found e ) {
			logError( e );
			return translateResource( "cms:rulesEngine.invalid.expression" );
		}

		return rendered;
	}

}