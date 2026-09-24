/**
 * @feature presideForms and customFields and rulesEngine
 */
component {

	public string function index( event, rc, prc, args={} ) {
		var multiple              = IsTrue( args.multiple ?: "" );
		var contextData           = UrlEncodedFormat( SerializeJson( args.rulesEngineContextData ?: {} ) );
		var preSavedFilters       = args.preSavedFilters ?: "";
		var preRulesEngineFilters = args.preRulesEngineFilters ?: "";
		var prefetchCacheBuster   = CreateUUId();

		args.object        = "rules_engine_condition";
		args.labelrenderer = "rules_engine_condition";
		args.remoteUrl = event.buildAdminLink(
			  linkTo      = "customFields.getFiltersForAggregateAjaxSelectControl"
			, querystring = "q=%QUERY"
		);
		args.prefetchUrl = event.buildAdminLink(
			  linkTo      = "customFields.getFiltersForAggregateAjaxSelectControl"
			, querystring = "maxRows=100&prefetchCacheBuster=#prefetchCacheBuster#"
		);
		args.placeholder = args.placeholder ?: "cms:rulesengine.filterPicker.placeholder";

		args.quickAdd  = IsTrue( args.quickAdd  ?: "" ) && hasCmsPermission( "rulesengine.add"  );
		args.quickEdit = IsTrue( args.quickEdit ?: "" ) && hasCmsPermission( "rulesengine.edit" );

		if ( args.quickAdd ) {
			args.quickAddUrl = event.buildAdminLink(
				  linkTo      = "customFields.quickAddAggregateFilterForm"
				, querystring = "multiple=#multiple#&contextData=#contextData#&preSavedFilters=#preSavedFilters#&preRulesEngineFilters=#preRulesEngineFilters#"
			);
		}
		if ( args.quickEdit ) {
			args.quickEditUrl = event.buildAdminLink(
				  linkTo      = "customFields.quickEditAggregateFilterForm"
				, querystring = "multiple=#multiple#&contextData=#contextData#&preSavedFilters=#preSavedFilters#&preRulesEngineFilters=#preRulesEngineFilters#&id="
			);
		}

		args.hasQuickAddPermission  = booleanFormat( hasCmsPermission( "rulesEngine.add" )  );
		args.hasQuickEditPermission = booleanFormat( hasCmsPermission( "rulesEngine.edit" ) );

		return renderViewlet( event="formcontrols.objectPicker.index", args=args );
	}

}
