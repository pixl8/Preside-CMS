component  {

	public string function index( event, rc, prc, args={} ) {
		var filterObject        = args.filterObject ?: "";
		var multiple            = IsTrue( args.multiple ?: "" );
		var prefetchCacheBuster = CreateUUId();

		args.object    = "rules_engine_filter";
		args.remoteUrl = event.buildAdminLink(
			  linkTo      = "rulesengine.getFiltersForAjaxSelectControl"
			, querystring = "filterObject=#filterObject#&q=%QUERY"
		);
		args.prefetchUrl = event.buildAdminLink(
			  linkTo      = "rulesengine.getFiltersForAjaxSelectControl"
			, querystring = "maxRows=100&prefetchCacheBuster=#prefetchCacheBuster#&filterObject=#filterObject#"
		);

		if ( IsTrue( args.quickAdd ?: "" ) ) {
			args.quickAddUrl = event.buildAdminLink(
				  linkTo      = "datamanager.quickAddForm"
				, querystring = "object=rules_engine_filter&object_name=#filterObject#&multiple=#multiple#"
			);
		}
		if ( IsTrue( args.quickEdit ?: "" ) ) {
			args.quickEditUrl = event.buildAdminLink(
				  linkTo      = "datamanager.quickEditForm"
				, querystring = "object=rules_engine_filter&object_name=#filterObject#&multiple=#multiple#"
			);
		}

		return renderViewlet( event="formcontrols.objectPicker.index", args=args );
	}
}