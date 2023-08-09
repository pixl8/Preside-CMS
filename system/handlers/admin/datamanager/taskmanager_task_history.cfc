component extends="preside.system.base.AdminHandler" {

	private void function extraRecordActionsForGridListing( event, rc, prc, args={} ) {
		args.actions = args.actions ?: [];

		ArrayAppend( args.actions, {
			  link  = event.buildAdminLink( linkTo="taskManager.viewLog", queryString='id=#args.record.id#' )
			, icon  = "fa-eye"
			, title = translateResource( "cms:taskmanager.history.viewlog.link" )
		} );
	}

}