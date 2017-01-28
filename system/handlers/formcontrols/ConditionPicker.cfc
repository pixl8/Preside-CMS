component  {

	public string function index( event, rc, prc, args={} ) {
		var context             = args.ruleContext ?: "webrequest";
		var multiple            = IsTrue( args.multiple ?: "" );
		var prefetchCacheBuster = CreateUUId();

		args.object    = "rules_engine_condition";
		args.remoteUrl = event.buildAdminLink(
			  linkTo      = "rulesengine.getConditionsForAjaxSelectControl"
			, querystring = "context=#context#&q=%QUERY"
		);
		args.prefetchUrl = event.buildAdminLink(
			  linkTo      = "rulesengine.getConditionsForAjaxSelectControl"
			, querystring = "maxRows=100&prefetchCacheBuster=#prefetchCacheBuster#&context=#context#"
		);

		if ( IsTrue( args.quickAdd ?: "" ) ) {
			args.quickAddUrl = event.buildAdminLink(
				  linkTo      = "datamanager.quickAddForm"
				, querystring = "object=rules_engine_condition&context=#context#&multiple=#multiple#"
			);
		}

		return renderViewlet( event="formcontrols.objectPicker.index", args=args );
	}
}