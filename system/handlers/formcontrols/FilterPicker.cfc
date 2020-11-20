component  {

	public string function index( event, rc, prc, args={} ) {
		var filterObject        = args.filterObject ?: ( rc.filterObject ?: "" );

		if ( !Len( Trim( filterObject ) ) ) {
			return "";
		}

		var multiple              = IsTrue( args.multiple ?: "" );
		var prefetchCacheBuster   = CreateUUId();
		var contextData           = UrlEncodedFormat( SerializeJson( args.rulesEngineContextData ?: {} ) );
		var preSavedFilters       = args.preSavedFilters ?: "";
		var preRulesEngineFilters = args.preRulesEngineFilters ?: "";

		args.object        = "rules_engine_condition";
		args.labelrenderer = "rules_engine_condition";
		args.remoteUrl = event.buildAdminLink(
			  linkTo      = "rulesengine.getFiltersForAjaxSelectControl"
			, querystring = "filterObject=#filterObject#&q=%QUERY"
		);
		args.prefetchUrl = event.buildAdminLink(
			  linkTo      = "rulesengine.getFiltersForAjaxSelectControl"
			, querystring = "maxRows=100&prefetchCacheBuster=#prefetchCacheBuster#&filterObject=#filterObject#"
		);
		args.placeholder = args.placeholder ?: "cms:rulesengine.filterPicker.placeholder"

		args.quickAdd  = IsTrue( args.quickAdd  ?: "" ) && hasCmsPermission( "rulesengine.add"  );
		args.quickEdit = IsTrue( args.quickEdit ?: "" ) && hasCmsPermission( "rulesengine.edit" );

		if ( args.quickAdd ) {
			args.quickAddUrl = event.buildAdminLink(
				  linkTo      = "rulesEngine.quickAddFilterForm"
				, querystring = "filter_object=#filterObject#&multiple=#multiple#&contextData=#contextData#&preSavedFilters=#preSavedFilters#&preRulesEngineFilters=#preRulesEngineFilters#"
			);
		}
		if ( args.quickEdit ) {
			args.quickEditUrl = event.buildAdminLink(
				  linkTo      = "rulesEngine.quickEditFilterForm"
				, querystring = "filter_object=#filterObject#&multiple=#multiple#&contextData=#contextData#&preSavedFilters=#preSavedFilters#&preRulesEngineFilters=#preRulesEngineFilters#&id="
			);
		}

		args.hasQuickAddPermission  = booleanFormat( hasCmsPermission( "rulesEngine.add" )  );
		args.hasQuickEditPermission = booleanFormat( hasCmsPermission( "rulesEngine.edit" ) );

		return renderViewlet( event="formcontrols.objectPicker.index", args=args );
	}
}