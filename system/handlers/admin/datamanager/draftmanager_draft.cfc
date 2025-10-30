component extends="preside.system.base.EnhancedDataManagerBase" {

	property name="presideObjectService"            inject="PresideObjectService";
	property name="dataManagerService"              inject="DataManagerService";
	property name="draftManagerService"             inject="DraftManagerService";
	property name="dataManagerCustomizationService" inject="DataManagerCustomizationService";
	property name="dataManagerWorkflowService"      inject="DataManagerWorkflowService";

	private void function rootBreadcrumb( event, rc, prc, args={} ) {
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:datamanager" )
			, link  = event.buildAdminLink( linkTo="datamanager" )
		);
	}

	private void function objectBreadcrumb( event, rc, prc, args={} ) {
		var objectName    = prc.record.object_name ?: "draftmanager_draft";
		var objectURIRoot = presideObjectService.getResourceBundleUriRoot( objectName=objectName );

		prc.objectTitle       = translateResource( uri="#objectURIRoot#title.singular", defaultValue=prc.objectTitle       );
		prc.objectTitlePlural = translateResource( uri="#objectURIRoot#title"         , defaultValue=prc.objectTitlePlural );
		prc.objectIconClass   = translateResource( uri="#objectURIRoot#iconClass"     , defaultValue=prc.objectIconClass   );

		event.addAdminBreadCrumb(
			  title = prc.objectTitlePlural
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

	private string function _defaultTab( event, rc, prc, args={} ) {
		args.objectName = prc.record.object_name ?: "";

		if ( !IsEmpty( args.record.data ?: {} ) ) {
			StructAppend( args.record, DeserializeJSON( args.record.data ), true );
		}

		return runEvent(
			  event          = "admin.DataHelpers.viewRecord"
			, private        = true
			, prepostExempt  = true
			, eventArguments = arguments
		);
	}

	private string function _workflowTab( event, rc, prc, args={} ) {
		args.objectName = "draftmanager_draft";

		return super._workflowTab( argumentCollection=arguments );
	}

	private string function _workflowTabTitle( event, rc, prc, args={} ) {
		args.objectName = "draftmanager_draft";

		return super._workflowTabTitle( argumentCollection=arguments );
	}

	private string function getAdditionalQueryStringForBuildAjaxListingLink( event, rc, prc, args={} ) {
		var objectName  = prc.objectName ?: "";
		var queryString = [];

		ArrayAppend( queryString, "object_name=#objectName#" );

		return ArrayToList( queryString, "&" );
	}

	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		var objectName = rc.object_name ?: "";

		args.extraFilters = args.extraFilters ?: [];

		if ( !isEmptyString( objectName ) ) {
			ArrayAppend( args.extraFilters, { filter={ object_name=objectName } } );
		}
	}

	private string function getEditRecordFormName( event, rc, prc, args={} ) {
		var objectName = prc.record.object_name ?: "";

		return dataManagerCustomizationService.runCustomization(
			  objectName     = objectName
			, action         = "getEditRecordFormName"
			, defaultHandler = "admin.DataManager._getEditRecordFormName"
			, args           = { objectName=objectName }
		);
	}

	private array function getEditRecordActionButtons( event, rc, prc, args={} ) {
		var objectName = prc.record.object_name ?: "";

		return runEvent(
			  event          = "admin.DraftManager._getEditRecordActionButtons"
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

	private any function editRecordAction( event, rc, prc ) {
		// Pretend to be the original object.
		arguments.object   = prc.record.object_name ?: "";
		arguments.recordId = prc.record.record_id   ?: "";

		arguments.checkExistingRecord = false;

		runEvent(
			  event          = "admin.DataManager._editRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = arguments
		);
	}

	private any function deleteRecordAction( event, rc, prc, batch=false, batchAll=false, batchSrcArgs={} ) {
		event.setValue( name="postActionUrl", value=event.buildAdminLink( objectName=( prc.record.object_name ?: "" ), operation="listing", queryString="tab=draft" ) );

		runEvent(
			  event          = "admin.DataManager._deleteRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  audit        = true
				, batch        = arguments.batch
				, batchAll     = arguments.batchAll
				, batchSrcArgs = arguments.batchSrcArgs
			  }
		);
	}

	private function getWorkflowForRecord( event, rc, prc, recordId="" ) {
		var objectName = prc.record.object_name ?: "";

		return draftManagerService.getWorkflowId( objectName=objectName );
	}

}