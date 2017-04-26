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

		event.include( "/js/admin/specific/rulesEngineConditionBuilder/"  )
		     .include( "/css/admin/specific/rulesEngineConditionBuilder/" )
		     .includeData( {
		     	  rulesEngineExpressions         = { "#args.id#" = args.expressions }
		     	, rulesEngineRenderFieldEndpoint = event.buildAdminLink( linkTo="rulesengine.ajaxRenderField" )
		     	, rulesEngineEditFieldEndpoint   = event.buildAdminLink( linkTo="rulesengine.editFieldModal" )
		     	, rulesEngineContext             = args.ruleContext
		     	, rulesEngineContextData         = args.contextData ?: {}
		      }  );

		return renderView( view="/formControls/rulesEngineConditionBuilder/index", args=args );
	}

}