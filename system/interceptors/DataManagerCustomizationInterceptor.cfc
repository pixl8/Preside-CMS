component extends="coldbox.system.Interceptor" {

	property name="presideObjectService" inject="delayedInjector:presideObjectService";

// PUBLIC
	public void function configure() {}

	public void function postRunCustomization( event, interceptData ) {
		var actionName       = arguments.interceptData.action     ?: "";
		var objectName       = arguments.interceptData.objectName ?: "";
		var objectGroupField = _getObjectDatamanagerListingGroupField( objectName=objectName );

		if ( Len( objectGroupField ) && Len( Trim( rc.activeGroupId ?: "" ) ) ) {

			if ( actionName == "getAdditionalQueryStringForBuildAjaxListingLink" ) {
				arguments.interceptData.result =  "activeGroupId=#rc.activeGroupId#";
			} else if ( actionName == "preFetchRecordsForGridListing" ) {
				arguments.interceptData.args              = arguments.interceptData.args              ?: {};
				arguments.interceptData.args.extraFilters = arguments.interceptData.args.extraFilters ?: [];

				ArrayAppend( arguments.interceptData.args.extraFilters, { filter={ "#objectGroupField#.id"=rc.activeGroupId } } );
			}

		}
	}

// PRIVATE HELPERS
	public string function _getObjectDatamanagerListingGroupField( required string objectName ) {
		return Len( arguments.objectName ) ? Trim( presideObjectService.getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "datamanagerListingGroupField"
		) ) : "";
	}
}