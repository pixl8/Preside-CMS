/**
 * Handler that provides default actions for building links to admin object
 * screens.
 *
 */
component {

	property name="dataManagerService" inject="dataManagerService";

	private string function buildViewRecordLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";
		var recordId   = args.recordId   ?: "";

		if ( dataManagerService.isOperationAllowed( objectName, "read" ) ) {
			return event.buildAdminLink(
				  linkto      = "datamanager.viewRecord"
				, queryString = "object=#objectName#&id=#recordId#"
			);
		}
		return "";
	}

	private string function buildListingLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		return event.buildAdminLink(
			  linkto      = "datamanager.object"
			, queryString = "id=#objectName#"
		);
	}

}