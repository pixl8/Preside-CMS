/**
 * @feature admin and customFields
 */
component extends="preside.system.base.AdminHandler" {

	property name="customFieldsService"           inject="customFieldsService";
	property name="customFieldsValueTableService" inject="customFieldsValueTableService";
	property name="formsService"                  inject="formsService";
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

	private void function _checkObjectEditPermission( event, rc, prc, required string objectName ) {
		if ( hasCmsPermission( "datamanager.edit" ) || hasCmsPermission( "presideobject.#arguments.objectName#.edit" ) ) {
			return;
		}

		event.adminAccessDenied();
	}

}
