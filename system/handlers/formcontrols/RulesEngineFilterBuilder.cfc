component {
	property name="expressionService" inject="rulesEngineExpressionService";

	private string function index( event, rc, prc, args={} ) {
		args.object      = args.object ?: ( rc.filter_object ?: "" );
		args.expressions = Len( Trim( args.object ) ) ? expressionService.listExpressions( filterObject=args.object ) : [];
		args.isFilter    = true;

		event.include( "/js/admin/specific/rulesEngineConditionBuilder/"  )
		     .include( "/css/admin/specific/rulesEngineConditionBuilder/" )
		     .includeData( {
		     	  rulesEngineExpressions           = { "#args.id#" = args.expressions }
		     	, rulesEngineRenderFieldEndpoint   = event.buildAdminLink( linkTo="rulesengine.ajaxRenderField" )
		     	, rulesEngineEditFieldEndpoint     = event.buildAdminLink( linkTo="rulesengine.editFieldModal" )
		     	, rulesEngineFilterCountEndpoint   = event.buildAdminLink( linkTo="rulesengine.getFilterCount" )
		     	, rulesEngineContext               = "global"
		     	, rulesEngineContextData           = args.contextData ?: {}
		     	, rulesEnginePreSavedFilters       = args.preSavedFilters ?: ""
		     	, rulesEnginePreRulesEngineFilters = args.preRulesEngineFilters ?: ""
		      }  );

		return renderView( view="/formControls/rulesEngineConditionBuilder/index", args=args );
	}

}