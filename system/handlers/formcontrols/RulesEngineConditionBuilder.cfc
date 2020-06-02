component {

	property name="expressionService" inject="rulesEngineExpressionService";

	private string function index( event, rc, prc, args={} ) {
		args.ruleContext = args.ruleContext ?: ( rc.context ?: "" );
		args.object      = rc.filter_object ?: "";

		if ( !args.ruleContext.len() && args.object.len() ) {
			return runEvent(
				  event          = "formcontrols.RulesEngineFilterBuilder.index"
				, eventArguments = { args=args }
				, private        = true
				, prePostExempt  = true
			);
		}

		args.expressions = expressionService.listExpressions( args.ruleContext );

		var fieldId = args.id ?: "";
		var expressionData = {
			"filter-builder-#fieldId#" = {
				  rulesEngineExpressions           = args.expressions
				, rulesEngineRenderFieldEndpoint   = event.buildAdminLink( linkTo="rulesengine.ajaxRenderField" )
				, rulesEngineEditFieldEndpoint     = event.buildAdminLink( linkTo="rulesengine.editFieldModal" )
				, rulesEngineContext               = args.ruleContext
				, rulesEngineContextData           = args.contextData ?: {}
			}
		};


		event.include( "/js/admin/specific/rulesEngineConditionBuilder/"  )
		     .include( "/css/admin/specific/rulesEngineConditionBuilder/" )
		     .includeData( expressionData );

		return renderView( view="/formControls/rulesEngineConditionBuilder/index", args=args );
	}

}