component  {

	public string function index( event, rc, prc, args={} ) {
		var object              = args.object ?: "";
		var multiple            = IsTrue( args.multiple ?: "" );
		var prefetchCacheBuster = CreateUUId();

		args.object    = "rules_engine_filter";
		args.remoteUrl = event.buildAdminLink(
			  linkTo      = "rulesengine.getFiltersForAjaxSelectControl"
			, querystring = "object=#object#&q=%QUERY"
		);
		args.prefetchUrl = event.buildAdminLink(
			  linkTo      = "rulesengine.getFiltersForAjaxSelectControl"
			, querystring = "maxRows=100&prefetchCacheBuster=#prefetchCacheBuster#&object=#object#"
		);

		if ( IsTrue( args.quickAdd ?: "" ) ) {
			args.quickAddUrl = event.buildAdminLink(
				  linkTo      = "datamanager.quickAddForm"
				, querystring = "object=rules_engine_filter&object=#object#&multiple=#multiple#"
			);
		}

		return renderViewlet( event="formcontrols.objectPicker.index", args=args );
	}
}