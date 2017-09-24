/**
 * Handler that provides admin related helper viewlets,
 * and actions for preside object data
 *
 */
component {


	/**
	 * Method that is called from `adminDataViewService.buildViewObjectRecordLink()`
	 * for objects that are managed in the DataManager. Hint: this can also be invoked with:
	 * `event.buildAdminLink( objectName=myObject, recordId=myRecordId )`
	 *
	 */
	private string function getViewRecordLink( required string objectName, required string recordId ) {
		return event.buildAdminLink(
			  linkto      = "datamanager.viewRecord"
			, queryString = "object=#arguments.objectName#&id=#arguments.recordId#"
		);
	}

}