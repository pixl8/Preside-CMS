component {

	property name="presideObjectService"            inject="PresideObjectService";
	property name="dataManagerService"              inject="DataManagerService";
	property name="dataManagerCustomizationService" inject="DataManagerCustomizationService";

	private void function objectBreadcrumb( event, rc, prc, args={} ) {
		var objectName = prc.record.object_name ?: "draftmanager_draft";

		prc.objectTitle = translateResource( uri=presideObjectService.getResourceBundleUriRoot( objectName=objectName ) & "title", defaultValue=objectName );

		event.addAdminBreadCrumb(
			  title = prc.objectTitle
			, link  = event.buildAdminLink( objectName=objectName, operation="listing" )
		);
	}

	private void function recordBreadcrumb( event, rc, prc, args={} ) {
		var objectName = prc.record.object_name ?: "";
		var recordId   = prc.record.id          ?: "";

		prc.recordLabel = translateResource( uri="draftManager:breadcrumb.record.title", data=[ prc.recordLabel ] );

		if ( dataManagerService.isOperationAllowed( objectName=objectName, operation="read" ) ) {
			event.addAdminBreadCrumb(
				  title = prc.recordLabel
				, link  = event.buildAdminLink( objectName="draftmanager_draft", recordId=recordId, operation="viewRecord" )
			);
		}
	}

	private string function getEditRecordFormName( event, rc, prc, args={} ) {
		var objectName = prc.record.object_name ?: "";

		return dataManagerCustomizationService.runCustomization(
			  objectName     = objectName
			, action         = "getEditRecordFormName"
			, defaultHandler = "admin.datamanager._getEditRecordFormName"
			, args           = { objectName=objectName }
		);
	}

	private array function getEditRecordActionButtons( event, rc, prc, args={} ) {
		// Override to resuse save draft button.
		args.draftsEnabled = true;
		args.canSaveDraft  = true;

		return runEvent(
			  event          = "admin.DataManager._getEditRecordActionButtons"
			, private        = true
			, prepostExempt  = true
			, eventArguments = arguments
		);
	}

	private string function editRecordForm( event, rc, prc, args={} ) {
		if ( !IsEmpty( args.record.data ?: {} ) ) {
			StructAppend( args.record, DeserializeJSON( args.record.data ), true );
		}

		return runEvent(
			  event          = "admin.DataManager._editRecordForm"
			, prepostExempt  = true
			, private        = true
			, eventArguments = arguments
		);
	}

}