/**
 * @feature admin and customFields
 */
component extends="preside.system.base.AdminHandler" {

	property name="customFieldsService"           inject="customFieldsService";
	property name="customFieldsValueTableService" inject="customFieldsValueTableService";
	property name="formsService"                  inject="formsService";
	property name="dataManagerService"            inject="dataManagerService";
	property name="messageBox"                    inject="messagebox@cbmessagebox";

	public void function editRecordValues( event, rc, prc ) {
		var objectName = rc.object ?: "";
		var recordId   = rc.id     ?: "";

		if ( !customFieldsService.isObjectEnabled( objectName ) || !Len( Trim( recordId ) ) ) {
			event.notFound();
		}

		_checkObjectEditPermission( argumentCollection=arguments, objectName=objectName );

		var record = getPresideObject( objectName ).selectData( id=recordId );
		if ( !record.recordCount ) {
			event.notFound();
		}

		prc.pageTitle    = translateResource( uri="customFields:edit.values.page.title" );
		prc.pageSubTitle = renderLabel( objectName, recordId );
		prc.pageIcon     = "puzzle-piece";
		prc.formName     = customFieldsService.buildValueEditFormName( objectName, record );
		prc.savedData    = customFieldsService.getValues( objectName, recordId );
		prc.objectName   = objectName;
		prc.recordId     = recordId;
		prc.cancelLink   = event.buildAdminLink( objectName=objectName, operation="viewRecord", recordId=recordId );
		prc.saveLink     = event.buildAdminLink( linkto="customFields.editRecordValuesAction" );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="preside-objects.#objectName#:title", defaultValue=objectName )
			, link  = event.buildAdminLink( objectName=objectName )
		);
		event.addAdminBreadCrumb(
			  title = prc.pageSubTitle
			, link  = prc.cancelLink
		);
		event.addAdminBreadCrumb(
			  title = prc.pageTitle
			, link  = ""
		);
	}

	public void function editRecordValuesAction( event, rc, prc ) {
		var objectName = rc.object ?: "";
		var recordId   = rc.id     ?: "";

		if ( !customFieldsService.isObjectEnabled( objectName ) || !Len( Trim( recordId ) ) ) {
			event.notFound();
		}

		_checkObjectEditPermission( argumentCollection=arguments, objectName=objectName );

		var record   = getPresideObject( objectName ).selectData( id=recordId );
		var formName = customFieldsService.buildValueEditFormName( objectName, record );
		var formData = event.getCollectionForForm( formName );

		customFieldsService.saveValues(
			  objectName = objectName
			, recordId   = recordId
			, values     = formData
			, record     = record
		);
		customFieldsValueTableService.forceHostVersion( objectName, recordId );
		customFieldsService.snapshotRecordValues( objectName, recordId );

		messageBox.info( translateResource( uri="customFields:edit.values.success" ) );
		setNextEvent( url=event.buildAdminLink( objectName=objectName, operation="viewRecord", recordId=recordId ) );
	}

	public void function fetchAggregateValueProperties( event, rc, prc ) {
		_checkManagePermission( argumentCollection=arguments );

		var targetObject      = rc.target_object      ?: "";
		var aggregateProperty = rc.aggregate_property ?: "";
		var relatedObject     = customFieldsService.getRelatedObjectForAggregateProperty( targetObject, aggregateProperty );
		var searchQuery       = LCase( Trim( rc.q ?: "" ) );
		var rendered          = [];

		if ( Len( relatedObject ) ) {
			for( var candidate in customFieldsService.listNumericRelatedProperties( relatedObject ) ) {
				if ( Len( searchQuery ) && !Find( searchQuery, LCase( candidate.label ?: "" ) ) && !Find( searchQuery, LCase( candidate.id ?: "" ) ) ) {
					continue;
				}
				ArrayAppend( rendered, { text=candidate.label, value=candidate.id } );
			}
		}

		event.renderData( type="json", data=rendered );
	}

	public void function fetchRelatedDataTreeNodes( event, rc, prc ) {
		_checkManagePermission( argumentCollection=arguments );

		var targetObject     = rc.target_object             ?: "";
		var relationshipPath = rc.related_data_relationship ?: "";

		event.renderData(
			  type = "json"
			, data = ( Len( targetObject ) && Len( relationshipPath ) ) ? customFieldsService.listRelatedDataTreeNodes(
				  objectName       = targetObject
				, relationshipPath = relationshipPath
			) : []
		);
	}

	public void function getFiltersForAggregateAjaxSelectControl( event, rc, prc ) {
		_checkManagePermission( argumentCollection=arguments );
		_applyRelatedFilterObject( rc );

		if ( !Len( Trim( rc.filterObject ?: "" ) ) ) {
			event.renderData( type="json", data=[] );
			return;
		}

		var records = dataManagerService.getRecordsForAjaxSelect(
			  objectName    = "rules_engine_condition"
			, maxRows       = rc.maxRows ?: 1000
			, searchQuery   = rc.q       ?: ""
			, savedFilters  = [ "globalRulesEngineFilters" ]
			, extraFilters  = [ { filter={ "rules_engine_condition.filter_object"=rc.filterObject ?: "" } } ]
			, ids           = ListToArray( rc.values ?: "" )
			, labelRenderer = "rules_engine_condition"
		);

		event.renderData( type="json", data=records );
	}

	public void function quickAddAggregateFilterForm( event, rc, prc ) {
		_checkManagePermission( argumentCollection=arguments );
		_applyRelatedFilterObject( rc );

		prc.modalClasses = "modal-dialog-less-padding";
		prc.contextData  = _deserializeContextData( rc.contextData ?: "" );

		event.include( "/js/admin/specific/datamanager/quickAddForm/" )
		     .include( "/js/admin/specific/rulesEngine/lockingform/" )
		     .include( "/js/admin/specific/saveFilterForm/" );

		event.setView( view="/admin/rulesEngine/quickAddFilterForm", layout="adminModalDialog" );
	}

	public void function quickEditAggregateFilterForm( event, rc, prc ) {
		_checkManagePermission( argumentCollection=arguments );
		_applyRelatedFilterObject( rc );

		runEvent(
			  event         = "admin.rulesEngine.quickEditFilterForm"
			, prePostExempt = true
		);
	}

	private void function _applyRelatedFilterObject( required struct rc ) {
		var filterObject = customFieldsService.getRelatedObjectForAggregateProperty(
			  arguments.rc.target_object      ?: ""
			, arguments.rc.aggregate_property ?: ""
		);

		arguments.rc.filterObject  = filterObject;
		arguments.rc.filter_object = filterObject;
	}

	private struct function _deserializeContextData( required string contextData ) {
		try {
			var data = DeSerializeJson( arguments.contextData );
			if ( IsStruct( data ) ) {
				return data;
			}
		} catch( any e ) {}

		return {};
	}

	private void function _checkManagePermission( event, rc, prc ) {
		if ( !hasCmsPermission( "customfields.edit" ) ) {
			event.adminAccessDenied();
		}
	}

	private void function _checkObjectEditPermission( event, rc, prc, required string objectName ) {
		if ( hasCmsPermission( "datamanager.edit" ) || hasCmsPermission( "presideobject.#arguments.objectName#.edit" ) ) {
			return;
		}

		event.adminAccessDenied();
	}

}
