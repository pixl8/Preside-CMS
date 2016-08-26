component  {

	public string function index( event, rc, prc, args={} ) {
		var context  = args.ruleContext ?: "webrequest";
		var multiple = IsTrue( args.multiple ?: "" );

		switch( context ) {
			case "webrequest":
				args.objectFilters = ListAppend( args.objectFilters ?: "", "webRequestConditions" );
			break;
		}

		args.object = "rules_engine_condition";
		if ( IsTrue( args.quickAdd ?: "" ) ) {
			args.quickAddUrl = event.buildAdminLink(
				  linkTo      = "datamanager.quickAddForm"
				, querystring = "object=rules_engine_condition&context=#context#&multiple=#multiple#"
			);
		}

		return renderViewlet( event="formcontrols.objectPicker.index", args=args );
	}
}