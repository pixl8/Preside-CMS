/**
 * @feature admin and taskManager
 */
component extends="preside.system.base.AdminHandler" {

	private string function getAdditionalQueryStringForBuildAjaxListingLink( event, rc, prc, args={} ) {
		var queryString = [];
		var task        = rc.task ?: "";

		if( !isEmptyString( rc.task ?: "" ) ) {
			ArrayAppend( queryString, "task_key=#rc.task#" );
		}

		return ArrayToList( queryString, "&" );
	}

	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		args.extraFilters = args.extraFilters ?: [];

		if( !isEmptyString( rc.task_key ?: "" ) ) {
			ArrayAppend( args.extraFilters, { filter={ "task_key"=task_key } } );
		}
	}

	private void function extraRecordActionsForGridListing( event, rc, prc, args={} ) {
		args.actions = args.actions ?: [];

		ArrayAppend( args.actions, {
			  link  = event.buildAdminLink( linkTo="taskManager.viewLog", queryString='id=#args.record.id#' )
			, icon  = "fa-eye"
			, title = translateResource( "cms:taskmanager.history.viewlog.link" )
		} );
	}

}