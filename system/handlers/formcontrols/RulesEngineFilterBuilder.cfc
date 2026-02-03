/**
 * @feature presideForms and rulesEngine
 */
component {
	property name="expressionService" inject="rulesEngineExpressionService";

	private string function index( event, rc, prc, args={} ) {
		args.object      = args.object      ?: ( rc.filter_object ?: "" );
		args.excludeTags = args.excludeTags ?: "";
		args.isFilter    = true;

		if ( isTrue( args.readonly ?: "" ) ) {
			return renderContent(
				  renderer = "rulesEngineConditionReadOnly"
				, data = args.defaultValue ?: ""
				, args = args
			);
		}

		var fieldId = args.id ?: "";
		var expressionData = {
			"filter-builder-#fieldId#" = {
				  rulesEngineExpressionEndpoint    = event.buildLink( filterExpressionsObject=args.object, excludeTags=args.excludeTags )
				, rulesEngineRenderFieldEndpoint   = event.buildAdminLink( linkTo="rulesengine.ajaxRenderField" )
				, rulesEngineEditFieldEndpoint     = event.buildAdminLink( linkTo="rulesengine.editFieldModal" )
				, rulesEngineFilterCountEndpoint   = event.buildAdminLink( linkTo="rulesengine.getFilterCount" )
				, rulesEngineContext               = "global"
				, rulesEngineContextData           = args.contextData ?: {}
				, rulesEnginePreSavedFilters       = args.preSavedFilters ?: ""
				, rulesEnginePreRulesEngineFilters = args.preRulesEngineFilters ?: ""
			}
		};

		event.include( "/js/admin/specific/rulesEngineConditionBuilder/"  )
			 .include( "/css/admin/specific/rulesEngineConditionBuilder/" )
			 .includeData( expressionData  );

		return renderView( view="/formControls/rulesEngineConditionBuilder/index", args=args );
	}

}