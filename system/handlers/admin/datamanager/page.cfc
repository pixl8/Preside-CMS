/**
 * @feature sitetree
 */
component extends="preside.system.base.AdminHandler" {

	property name="pageTypesService" inject="pageTypesService";

	private string function buildViewRecordLink( event, rc, prc, args={} ) {
		return buildEditRecordLink( argumentCollection=arguments );
	}

	private string function buildEditRecordLink( event, rc, prc, args={} ) {
		return event.buildAdminLink( linkTo="sitetree.editPage", querystring="id=#( args.recordId ?: "" )#" );
	}

	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		args.extraFilters = args.extraFilters ?: [];

		ArrayAppend( args.extraFilters, { filter={
			  trashed   = false
			, page_type = pageTypesService.listSiteTreePageTypes()
		} } );
	}

	private void function postDecorateRecordsForGridListing( event, rc, prc, args={} ) {
		var i=1;
		var records = args.records ?: queryNew( '' );

		for ( var record in records ) {
			querySetCell( records, "page_type", renderContent( "ObjectName", record.page_type, "admindatatable" ), i++ );
		}
	}

	private void function extraRecordActionsForGridListing( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";
		var record     = args.record     ?: {};
		var recordId   = record.id       ?: "";

		args.actions = args.actions ?: [];

		for ( var action in args.actions ) {
			if ( Find( "/sitetree/editPage/", action.link ) ) {
				action.link &= "&tab=listing";
			}
		}

	}
}