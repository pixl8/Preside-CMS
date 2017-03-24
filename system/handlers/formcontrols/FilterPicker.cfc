component  {

	public string function index( event, rc, prc, args={} ) {
		var filterObject        = args.filterObject ?: ( rc.filterObject ?: "" );

		if ( !Len( Trim( filterObject ) ) ) {
			return "";
		}

		var multiple            = IsTrue( args.multiple ?: "" );
		var prefetchCacheBuster = CreateUUId();

		args.object    = "rules_engine_condition";
		args.remoteUrl = event.buildAdminLink(
			  linkTo      = "rulesengine.getFiltersForAjaxSelectControl"
			, querystring = "filterObject=#filterObject#&q=%QUERY"
		);
		args.prefetchUrl = event.buildAdminLink(
			  linkTo      = "rulesengine.getFiltersForAjaxSelectControl"
			, querystring = "maxRows=100&prefetchCacheBuster=#prefetchCacheBuster#&filterObject=#filterObject#"
		);
		args.placeholder = args.placeholder ?: "cms:rulesengine.filterPicker.placeholder"

		if ( IsTrue( args.quickAdd ?: "" ) ) {
			args.quickAddUrl = event.buildAdminLink(
				  linkTo      = "rulesEngine.quickAddFilterForm"
				, querystring = "filter_object=#filterObject#&multiple=#multiple#"
			);
		}
		if ( IsTrue( args.quickEdit ?: "" ) ) {
			args.quickEditUrl = event.buildAdminLink(
				  linkTo      = "rulesEngine.quickEditFilterForm"
				, querystring = "filter_object=#filterObject#&multiple=#multiple#&id="
			);
		}

		return renderViewlet( event="formcontrols.objectPicker.index", args=args );
	}
}