component extends="preside.system.base.AdminHandler" {

	property name="presideObjectService"             inject="presideObjectService";
	property name="multilingualPresideObjectService" inject="multilingualPresideObjectService";
	property name="dataManagerService"               inject="dataManagerService";
	property name="customizationService"             inject="dataManagerCustomizationService";
	property name="dataExportService"                inject="dataExportService";
	property name="formsService"                     inject="formsService";
	property name="validationEngine"                 inject="validationEngine";
	property name="siteService"                      inject="siteService";
	property name="versioningService"                inject="versioningService";
	property name="rulesEngineFilterService"         inject="rulesEngineFilterService";
	property name="adminDataViewsService"            inject="adminDataViewsService";
	property name="dtHelper"                         inject="jqueryDatatablesHelpers";
	property name="messageBox"                       inject="messagebox@cbmessagebox";


	public void function preHandler( event, action, eventArguments ) {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "datamanager" ) ) {
			event.notFound();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:datamanager" )
			, link  = event.buildAdminLink( linkTo="datamanager" )
		);
	}

	public void function index( event, rc, prc ) {
		_checkNavigatePermission( argumentCollection=arguments );

		prc.objectGroups = dataManagerService.getGroupedObjects();
	}

	public void function object( event, rc, prc ) {
		var objectName   = event.getValue( name="id", default="" );
		_checkObjectExists( argumentCollection=arguments, object=objectName );
		_checkPermission( argumentCollection=arguments, key="navigate", object=objectName );

		_objectCanBeViewedInDataManager( event=event, objectName=objectName, relocateIfNoAccess=true );

		_addObjectNameBreadCrumb( event, objectName );

		prc.draftsEnabled = datamanagerService.areDraftsEnabledForObject( objectName );
		prc.canAdd        = datamanagerService.isOperationAllowed( objectName, "add" )    && hasCmsPermission( permissionKey="datamanager.add", context="datamanager", contextkeys=[ objectName ] );
		prc.canDelete     = datamanagerService.isOperationAllowed( objectName, "delete" ) && hasCmsPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ objectName ] );
		prc.canSort       = datamanagerService.isSortable( objectName ) && hasCmsPermission( permissionKey="datamanager.edit", context="datamanager", contextKeys=[ objectName ] );

		prc.gridFields          = _getObjectFieldsForGrid( objectName );
		prc.batchEditableFields = dataManagerService.listBatchEditableFields( objectName );
		prc.isMultilingual      = multilingualPresideObjectService.isMultilingual( objectName );
	}

	public void function getObjectRecordsForAjaxDataTables( event, rc, prc ) {
		var objectName = rc.id ?: "";

		_checkPermission( argumentCollection=arguments, key="read", object=objectName, checkOperations=false );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object              = objectName
				, useMultiActions     = hasCmsPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ objectName ] )
				, gridFields          = ( rc.gridFields          ?: 'label,datecreated,datemodified' )
				, isMultilingual      = IsTrue( rc.isMultilingual ?: 'false' )
				, draftsEnabled       = IsTrue( rc.draftsEnabled  ?: 'false' )
			}
		);
	}

	public void function getChildObjectRecordsForAjaxDataTables( event, rc, prc ) {
		var objectName      = rc.object          ?: "";
		var parentId        = rc.parentId        ?: "";
		var relationshipKey = rc.relationshipKey ?: "";

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object          = objectName
				, useMultiActions = hasCmsPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ objectName ] )
				, gridFields      = ( rc.gridFields ?: 'label,datecreated,datemodified' )
				, actionsView     = "/admin/datamanager/_oneToManyListingActions"
				, filter          = { "#relationshipKey#" : parentId }
			}
		);
	}

	public void function getRecordHistoryForAjaxDataTables( event, rc, prc ) {
		var objectName = rc.object ?: "";
		var recordId   = rc.id     ?: "";

		_checkPermission( argumentCollection=arguments, key="viewversions", object=objectName );

		runEvent(
			  event          = "admin.DataManager._getRecordHistoryForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object     = objectName
				, recordId   = recordId
				, gridFields = ( rc.gridFields ?: 'datemodified,label' )
			}
		);
	}

	public void function getTranslationRecordHistoryForAjaxDataTables( event, rc, prc ) {
		var objectName = rc.object   ?: "";
		var recordId   = rc.id       ?: "";
		var languageId = rc.language ?: "";

		_checkPermission( argumentCollection=arguments, key="translate", object=objectName );
		_checkPermission( argumentCollection=arguments, key="viewversions", object=objectName );

		runEvent(
			  event          = "admin.DataManager._getTranslationRecordHistoryForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object     = objectName
				, recordId   = recordId
				, languageId = languageId
				, gridFields = ( rc.gridFields ?: 'datemodified,label' )
			}
		);
	}

	public void function getObjectRecordsForAjaxSelectControl( event, rc, prc ) {
		var objectName     = rc.object ?: "";
		var extraFilters   = [];
		var filterByFields = ListToArray( rc.filterByFields ?: "" );
		var filterValue    = "";
		var orderBy        = rc.orderBy       ?: "label";
		var labelRenderer  = rc.labelRenderer ?: "";

		_checkPermission( argumentCollection=arguments, key="read", object=objectName, checkOperations=false );

		for( var filterByField in filterByFields ) {
			filterValue = rc[filterByField] ?: "";
			if( !isEmpty( filterValue ) ){
				extraFilters.append({ filter = { "#filterByField#" = listToArray( filterValue ) } });
			}
		}

		var records = dataManagerService.getRecordsForAjaxSelect(
			  objectName    = rc.object  ?: ""
			, maxRows       = rc.maxRows ?: 1000
			, searchQuery   = rc.q       ?: ""
			, savedFilters  = ListToArray( rc.savedFilters ?: "" )
			, extraFilters  = extraFilters
			, orderBy       = orderBy
			, ids           = ListToArray( rc.values ?: "" )
			, labelRenderer = labelRenderer
		);

		event.renderData( type="json", data=records );
	}

	public void function managePerms( event, rc, prc ) {
		var objectName = event.getValue( name="object", defaultValue="" );

		_checkObjectExists( argumentCollection=arguments, object=objectName );
		_objectCanBeViewedInDataManager( event=event, objectName=objectName, relocateIfNoAccess=true );
		_checkPermission( argumentCollection=arguments, key="manageContextPerms", object=objectName );

		_addObjectNameBreadCrumb( event, objectName );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:datamanager.managePerms.breadcrumb.title" )
			, link  = ""
		);
	}

	public void function savePermsAction( event, rc, prc ) {
		var objectName = event.getValue( name="object", defaultValue="" );

		_checkObjectExists( argumentCollection=arguments, object=objectName );
		_objectCanBeViewedInDataManager( event=event, objectName=objectName, relocateIfNoAccess=true );
		_checkPermission( argumentCollection=arguments, key="manageContextPerms", object=objectName );

		if ( runEvent( event="admin.Permissions.saveContextPermsAction", private=true ) ) {
			event.audit(
				  action   = "edit_datamanager_object_admin_permissions"
				, type     = "datamanager"
				, recordId = objectName
				, detail   = { objectName=objectName }
			);

			messageBox.info( translateResource( uri="cms:datamanager.permsSaved.confirmation", data=[ objectName ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", queryString="id=#objectName#" ) );
		}

		messageBox.error( translateResource( uri="cms:datamanager.permsSaved.error", data=[ objectName ] ) );
		setNextEvent( url=event.buildAdminLink( linkTo="datamanager.managePerms", queryString="object=#objectName#" ) );
	}

	public void function viewRecord( event, rc, prc ) {
		var object     = rc.object   ?: "";
		var recordId   = rc.id       ?: "";
		var language   = rc.language ?: "";
		var version    = rc.version = rc.version ?: ( presideObjectService.objectIsVersioned( object ) ? versioningService.getLatestVersionNumber( object, recordId ) : 0 );

		_checkObjectExists( argumentCollection=arguments, object=object );
		_objectCanBeViewedInDataManager( event=event, objectName=object, relocateIfNoAccess=true );
		_checkPermission( argumentCollection=arguments, key="read", object=object );

		if ( language.len() ) {
			prc.language = multilingualPresideObjectService.getLanguage( language );

			if ( prc.language.isempty() ) {
				messageBox.error( translateResource( uri="cms:multilingual.language.not.active.error" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.viewRecord", queryString="object=#object#&id=#id#" ) );
			}
			event.setLanguage( language );
		}

		prc.useVersioning = !language.len() && datamanagerService.isOperationAllowed( object, "viewversions" ) && presideObjectService.objectIsVersioned( object );
		prc.objectName = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );


		prc.renderedRecord = adminDataViewsService.renderObjectRecord(
			  objectName = object
			, recordId   = recordId
			, version    = version
		);

		try {
			prc.recordLabel = renderLabel( object, recordId );
		} catch ( "PresideObjectService.no.label.field" e ) {
			prc.recordLabel = recordId;
		}
		prc.isMultilingual = multilingualPresideObjectService.isMultilingual( object );
		prc.canTranslate   = prc.isMultilingual && hasCmsPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ object ] );
		prc.canDelete      = datamanagerService.isOperationAllowed( object, "delete" ) && hasCmsPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ object ] );
		prc.canEdit        = datamanagerService.isOperationAllowed( object, "edit"   ) && hasCmsPermission( permissionKey="datamanager.edit"  , context="datamanager", contextKeys=[ object ] );

		if ( prc.canTranslate ) {
			prc.translations = multilingualPresideObjectService.getTranslationStatus( object, id );
		}

		_addObjectNameBreadCrumb( event, object );
		_addViewRecordBreadCrumb( event, object, recordId );

		prc.pageTitle    = translateResource( uri="cms:datamanager.viewrecord.page.title"   , data=[ prc.objectName ] );
		prc.pageSubtitle = translateResource( uri="cms:datamanager.viewrecord.page.subtitle", data=[ prc.recordLabel ] );
	}

	public void function recordHistory( event, rc, prc ) {
		var object     = rc.object ?: "";
		var objectName = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
		var recordId   = rc.id     ?: "";

		_checkObjectExists( argumentCollection=arguments, object=object );
		_objectCanBeViewedInDataManager( event=event, objectName=object, relocateIfNoAccess=true );
		_checkPermission( argumentCollection=arguments, key="viewversions", object=object );

		if ( !presideObjectService.objectIsVersioned( object ) ) {
			messageBox.error( translateResource( uri="cms:datamanager.recordNot.error", data=[ objectName  ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
		}

		prc.record = presideObjectService.selectData( objectName=object, filter={ id=id }, useCache=false, allowDraftVersions=true );
		if ( !prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ objectName  ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
		}

		// breadcrumb setup
		_addObjectNameBreadCrumb( event, object );
		_addViewRecordBreadCrumb( event, object, recordId );
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:datamanager.recordhistory.breadcrumb.title" )
			, link  = ""
		);
	}

	public void function translationRecordHistory( event, rc, prc ) {
		var object     = rc.object   ?: "";
		var recordId   = rc.id       ?: "";
		var languageId = rc.language ?: "";
		var objectName = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );

		prc.language = multilingualPresideObjectService.getLanguage( languageId );

		if ( prc.language.isempty() ) {
			messageBox.error( translateResource( uri="cms:multilingual.language.not.active.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.editRecord", queryString="object=#object#&id=#id#" ) );
		}

		_checkObjectExists( argumentCollection=arguments, object=object );
		_objectCanBeViewedInDataManager( event=event, objectName=object, relocateIfNoAccess=true );
		_checkPermission( argumentCollection=arguments, key="translate"   , object=object );
		_checkPermission( argumentCollection=arguments, key="viewversions", object=object );

		if ( !presideObjectService.objectIsVersioned( object ) ) {
			messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ objectName  ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
		}

		prc.record = presideObjectService.selectData( objectName=object, filter={ id=id }, useCache=false );
		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ objectName  ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
		}
		prc.recordLabel = prc.record[ presideObjectService.getObjectAttribute( objectName=object, attributeName="labelfield", defaultValue="label" ) ] ?: "";

		// breadcrumb setup
		_addObjectNameBreadCrumb( event, object );
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:datamanager.translaterecord.breadcrumb.title", data=[ prc.language.name ] )
			, link  = event.buildAdminLink( linkTo="datamanager.translateRecord", queryString="object=#object#&id=#recordId#&language=#languageId#" )
		);
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:datamanager.translationRecordhistory.breadcrumb.title" )
			, link  = ""
		);
	}

	public void function batchEditField( event, rc, prc ) {
		var object      = rc.object;
		var field       = rc.field ?: "";
		var formControl = {};
		var ids         = rc.id ?: "";
		var recordCount = ListLen( Trim( ids ) );
		var objectName  = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object ?: "" );
		var fieldName   = translateResource( uri="preside-objects.#object#:field.#field#.title", defaultValue=field );

		_checkObjectExists( argumentCollection=arguments, object=object );
		_checkPermission( argumentCollection=arguments, key="edit", object=object );
		if ( !recordCount ) {
			messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ objectName  ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
		}

		prc.fieldFormControl = formsService.renderFormControlForObjectField(
		      objectName = object
		    , fieldName  = field
		);

		if ( presideObjectService.isManyToManyProperty( object, field ) ) {
			prc.multiEditBehaviourControl = renderFormControl(
				  type   = "select"
				, name   = "multiValueBehaviour"
				, label  = translateResource( uri="cms:datamanager.multiValueBehaviour.title" )
				, values = [ "append", "overwrite", "delete" ]
				, labels = [ translateResource( uri="cms:datamanager.multiDataAppend.title" ), translateResource( uri="cms:datamanager.multiDataOverwrite.title" ), translateResource( uri="cms:datamanager.multiDataDeleteSelected.title" ) ]
			);

			prc.batchEditWarning = translateResource(
				  uri  = "cms:datamanager.batch.edit.warning.multi.value"
				, data = [ "<strong>#objectName#</strong>", "<strong>#fieldName#</strong>", "<strong>#NumberFormat( recordCount )#</strong>" ]
			);
		} else {
			prc.batchEditWarning = translateResource(
				  uri  = "cms:datamanager.batch.edit.warning"
				, data = [ "<strong>#objectName#</strong>", "<strong>#fieldName#</strong>", "<strong>#NumberFormat( recordCount )#</strong>" ]
			);
		}

		prc.pageTitle    = translateResource( uri="cms:datamanager.batchEdit.page.title"   , data=[ objectName, NumberFormat( recordCount ) ] );
		prc.pageSubtitle = translateResource( uri="cms:datamanager.batchEdit.page.subtitle", data=[ fieldName ] );
		prc.pageIcon     = "pencil";

		_addObjectNameBreadCrumb( event, object );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:datamanager.batchedit.breadcrumb.title", data=[ objectName, fieldName ] )
			, link  = ""
		);

		event.setView( view="/admin/datamanager/batchEditField" );
	}

	public void function batchEditAction( event, rc, prc ) {
		var updateField = rc.updateField ?: "";
		var objectName  = rc.objectName  ?: "";
		var sourceIds   = ListToArray( Trim( rc.sourceIds ?: "" ) );

		_checkObjectExists( argumentCollection=arguments, object=objectName );
		_checkPermission( argumentCollection=arguments, key="edit", object=objectName );
		if ( !sourceIds.len() ) {
			messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ objectName  ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
		}

		var success = datamanagerService.batchEditField(
			  objectName         = objectName
			, fieldName          = updateField
			, sourceIds          = sourceIds
			, value              = rc[ updateField ]      ?: ""
			, multiEditBehaviour = rc.multiValueBehaviour ?: "append"
		);

		if( success ) {
			messageBox.info( translateResource( uri="cms:datamanager.batchedit.confirmation", data=[ objectName ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", queryString="id=#objectName#" ) );
		} else {
			messageBox.error( translateResource( uri="cms:datamanager.batchedit.error", data=[ objectName ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", queryString="id=#objectName#" ) );
		}
	}

	public void function deleteRecordAction( event, rc, prc ) {
		var objectName = rc.object ?: "";

		_checkObjectExists( argumentCollection=arguments, object=objectName );
		_checkPermission( argumentCollection=arguments, key="delete", object=objectName );

		runEvent(
			  event          = "admin.DataManager._deleteRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = { audit=true }
		);
	}

	public void function deleteOneToManyRecordAction( event, rc, prc ) {
		var objectName      = rc.object ?: "";
		var relationshipKey = rc.relationshipKey ?: "";
		var parentId        = rc.parentId ?: "";

		_checkObjectExists( argumentCollection=arguments, object=objectName );
		if ( !datamanagerService.isOperationAllowed( objectName, "delete"   ) ) {
			event.adminAccessDenied();
		}
		rc.forceDelete = true;

		runEvent(
			  event          = "admin.DataManager._deleteRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  postActionUrl = event.buildAdminLink( linkTo="datamanager.manageOneToManyRecords", queryString="object=#objectName#&relationshipKey=#relationshipKey#&parentId=#parentId#" )
				, audit         = true
			}
		);
	}

	public void function cascadeDeletePrompt( event, rc, prc ) {
		var objectName = rc.object ?: "";

		prc.id       = rc.id       ?: "";
		prc.blockers = rc.blockers ?: {};

		_checkObjectExists( argumentCollection=arguments, object=objectName );
		_checkPermission( argumentCollection=arguments, key="delete", object=objectName );

		_addObjectNameBreadCrumb( event, objectName );
		_addViewRecordBreadCrumb(event, objectName, prc.id );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:datamanager.cascadeDelete.breadcrumb.title" )
			, link  = ""
		);
	}

	public void function addRecord( event, rc, prc ) {
		var objectName = event.getValue( name="object", defaultValue="" );

		_checkObjectExists( argumentCollection=arguments, object=objectName );
		_objectCanBeViewedInDataManager( event=event, objectName=objectName, relocateIfNoAccess=true );
		_checkPermission( argumentCollection=arguments, key="add", object=objectName );

		prc.draftsEnabled = dataManagerService.areDraftsEnabledForObject( objectName );
		if ( prc.draftsEnabled ) {
			prc.canPublish   = _checkPermission( argumentCollection=arguments, key="publish"  , object=objectName, throwOnError=false );
			prc.canSaveDraft = _checkPermission( argumentCollection=arguments, key="savedraft", object=objectName, throwOnError=false );

			if ( !prc.canPublish && !prc.canSaveDraft ) {
				event.adminAccessDenied();
			}
		}

		_addObjectNameBreadCrumb( event, objectName );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:datamanager.addrecord.breadcrumb.title" )
			, link  = ""
		);
	}

	public void function addRecordAction( event, rc, prc ) {
		var objectName = rc.object ?: "";
		_checkObjectExists( argumentCollection=arguments, object=objectName );
		_checkPermission( argumentCollection=arguments, key="add", object=objectName );

		prc.draftsEnabled = dataManagerService.areDraftsEnabledForObject( objectName );
		if ( prc.draftsEnabled ) {
			prc.canPublish   = _checkPermission( argumentCollection=arguments, key="publish"  , object=objectName, throwOnError=false );
			prc.canSaveDraft = _checkPermission( argumentCollection=arguments, key="savedraft", object=objectName, throwOnError=false );

			if ( !prc.canPublish && !prc.canSaveDraft ) {
				event.adminAccessDenied();
			}
		}

		runEvent(
			  event          = "admin.DataManager._addRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  audit         = true
				, draftsEnabled = prc.draftsEnabled
				, canPublish    = IsTrue( prc.canPublish   ?: "" )
				, canSaveDraft  = IsTrue( prc.canSaveDraft ?: "" )
			  }
		);
	}

	public void function addOneToManyRecordAction( event, rc, prc ) {
		var objectName = rc.object ?: "";

		_checkObjectExists( argumentCollection=arguments, object=objectName );
		if ( !datamanagerService.isOperationAllowed( objectName, "add"   ) ) {
			event.adminAccessDenied();
		}

		runEvent(
			  event          = "admin.DataManager._addOneToManyRecordAction"
			, prePostExempt  = true
			, private        = true
		);
	}

	public void function quickAddForm( event, rc, prc ) {
		var object = rc.object ?: "";
		var args   = {};

		_checkObjectExists( argumentCollection=arguments, object=object );
		_checkPermission( argumentCollection=arguments, key="add", object=object );

		args.allowAddAnotherSwitch = IsTrue( rc.multiple ?: "" );

		event.setView( view="/admin/datamanager/quickAddForm", layout="adminModalDialog", args=args );
	}

	public void function quickAddRecordAction( event, rc, prc ) {
		var object = rc.object ?: "";

		_checkObjectExists( argumentCollection=arguments, object=object );
		_checkPermission( argumentCollection=arguments, key="add", object=object );

		runEvent(
			  event          = "admin.DataManager._quickAddRecordAction"
			, prePostExempt  = true
			, private        = true
		);
	}

	public void function quickEditForm( event, rc, prc ) {
		var object = rc.object ?: "";
		var id     = rc.id     ?: "";

		_checkObjectExists( argumentCollection=arguments, object=object );
		_checkPermission( argumentCollection=arguments, key="edit", object=object );

		prc.record = presideObjectService.selectData( objectName=object, filter={ id=id }, useCache=false );
		if ( prc.record.recordCount ) {
			prc.record = queryRowToStruct( prc.record );
		} else {
			prc.record = {};
		}

		event.setView( view="/admin/datamanager/quickEditForm", layout="adminModalDialog" );
	}

	public void function quickEditRecordAction( event, rc, prc ) {
		var objectName = rc.object ?: "";

		_checkObjectExists( argumentCollection=arguments, object=objectName );
		_checkPermission( argumentCollection=arguments, key="edit", object=objectName );

		runEvent(
			  event          = "admin.DataManager._quickEditRecordAction"
			, prePostExempt  = true
			, private        = true
		);
	}

	public void function configuratorForm( event, rc, prc ) {
		var object     = rc.object   ?: "";
		var id         = rc.id       ?: "";
		var fromDb     = rc.__fromDb ?: false;
		var args       = {};
		var objectName = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
		var record     = "";

		_checkObjectExists( argumentCollection=arguments, object=object );
		_checkPermission( argumentCollection=arguments, key="add", object=object );

		if ( fromDb ) {
			record = presideObjectService.selectData( objectName=object, id=id, useCache=false );
			if ( record.recordCount ) {
				args.savedData = queryRowToStruct( record );
			}
		}
		args.sourceIdField = rc.sourceIdField ?: "";
		args.sourceId      = rc.sourceId      ?: "";

		event.setView( view="/admin/datamanager/configuratorForm", layout="adminModalDialog", args=args );
	}

	public void function editRecord( event, rc, prc ) {
		var object       = rc.object  ?: "";
		var id           = rc.id      ?: "";
		var version      = rc.version = rc.version ?: ( presideObjectService.objectIsVersioned( object ) ? versioningService.getLatestVersionNumber( object, id ) : 0 );
		var objectName   = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
		var record       = "";
		var resultAction = rc.resultAction ?: "";

		_checkObjectExists( argumentCollection=arguments, object=object );
		_objectCanBeViewedInDataManager( event=event, objectName=object, relocateIfNoAccess=true );
		_checkPermission( argumentCollection=arguments, key="edit", object=object );

		prc.draftsEnabled = dataManagerService.areDraftsEnabledForObject( object );
		if ( prc.draftsEnabled ) {
			prc.canPublish   = _checkPermission( argumentCollection=arguments, key="publish"  , object=object, throwOnError=false );
			prc.canSaveDraft = _checkPermission( argumentCollection=arguments, key="savedraft", object=object, throwOnError=false );

			if ( !prc.canPublish && !prc.canSaveDraft ) {
				event.adminAccessDenied();
			}
		}

		prc.useVersioning = datamanagerService.isOperationAllowed( object, "viewversions" ) && presideObjectService.objectIsVersioned( object );
		if ( prc.useVersioning && Val( version ) ) {
			prc.record = presideObjectService.selectData( objectName=object, filter={ id=id }, useCache=false, fromVersionTable=true, specificVersion=version, allowDraftVersions=true );
		} else {
			prc.record = presideObjectService.selectData( objectName=object, filter={ id=id }, useCache=false, allowDraftVersions=true );
		}

		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ objectName  ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
		}

		prc.record = queryRowToStruct( prc.record );
		prc.recordLabel = prc.record[ presideObjectService.getObjectAttribute( objectName=object, attributeName="labelfield", defaultValue="label" ) ] ?: "";

		prc.isMultilingual = multilingualPresideObjectService.isMultilingual( object );
		prc.canTranslate   = prc.isMultilingual && hasCmsPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ object ] );

		if ( prc.canTranslate ) {
			prc.translations = multilingualPresideObjectService.getTranslationStatus( object, id );
		}

		switch( resultAction ) {
			case "grid":
				prc.cancelAction = event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" );
			break;
			default:
				prc.cancelAction = event.buildAdminLink( linkTo="datamanager.viewRecord", querystring="object=#object#&id=#id#" );
		}

		// breadcrumb setup
		_addObjectNameBreadCrumb( event, object );
		_addViewRecordBreadCrumb( event, object, id );
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:datamanager.editrecord.breadcrumb.title" )
			, link  = ""
		);
	}

	public void function editRecordAction( event, rc, prc ) {
		var objectName = rc.object ?: "";
		var recordId   = rc.id     ?: "";

		_checkObjectExists( argumentCollection=arguments, object=objectName );
		_checkPermission( argumentCollection=arguments, key="edit", object=objectName );

		prc.draftsEnabled = dataManagerService.areDraftsEnabledForObject( objectName );
		if ( prc.draftsEnabled ) {
			prc.canPublish   = _checkPermission( argumentCollection=arguments, key="publish"  , object=objectName, throwOnError=false );
			prc.canSaveDraft = _checkPermission( argumentCollection=arguments, key="savedraft", object=objectName, throwOnError=false );

			if ( !prc.canPublish && !prc.canSaveDraft ) {
				event.adminAccessDenied();
			}
		}

		var successUrl = "";
		switch( rc.__resultAction ?: "" ) {
			case "grid":
				successUrl = event.buildAdminLink( linkTo="datamanager.object", querystring="id=#objectName#" );
			break;
			default:
				successUrl = event.buildAdminLink( linkTo="datamanager.viewRecord", querystring="object=#objectName#&id=#recordId#" );
		}

		runEvent(
			  event          = "admin.DataManager._editRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  audit         =true
				, draftsEnabled = prc.draftsEnabled
				, canPublish    = IsTrue( prc.canPublish   ?: "" )
				, canSaveDraft  = IsTrue( prc.canSaveDraft ?: "" )
				, successUrl    = successUrl
			  }
		);
	}

	public void function translateRecord( event, rc, prc ) {
		var object                = rc.object       ?: "";
		var id                    = rc.id           ?: "";
		var version               = rc.version      ?: "";
		var fromDataGrid          = rc.fromDataGrid ?: "";
		var objectName            = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
		var translationObjectName = multilingualPresideObjectService.getTranslationObjectName( object );
		var record                = "";

		prc.language = multilingualPresideObjectService.getLanguage( rc.language ?: "" );

		if ( prc.language.isempty() ) {
			messageBox.error( translateResource( uri="cms:multilingual.language.not.active.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.editRecord", queryString="object=#object#&id=#id#" ) );
		}

		_checkObjectExists( argumentCollection=arguments, object=object );
		_objectCanBeViewedInDataManager( event=event, objectName=object, relocateIfNoAccess=true );
		_checkPermission( argumentCollection=arguments, key="translate", object=object );

		prc.draftsEnabled = dataManagerService.areDraftsEnabledForObject( object );
		if ( prc.draftsEnabled ) {
			prc.canPublish   = _checkPermission( argumentCollection=arguments, key="publish"  , object=object, throwOnError=false );
			prc.canSaveDraft = _checkPermission( argumentCollection=arguments, key="savedraft", object=object, throwOnError=false );

			if ( !prc.canPublish && !prc.canSaveDraft ) {
				event.adminAccessDenied();
			}
		}

		prc.useVersioning = presideObjectService.objectIsVersioned( object );
		prc.sourceRecord = presideObjectService.selectData( objectName=object, filter={ id=id }, useCache=false );

		if ( prc.useVersioning && Val( version ) ) {
			prc.record       = multiLingualPresideObjectService.selectTranslation( objectName=object, id=id, languageId=prc.language.id, useCache=false, version=version );
		} else {
			prc.record       = multiLingualPresideObjectService.selectTranslation( objectName=object, id=id, languageId=prc.language.id, useCache=false );
		}

		if ( not prc.sourceRecord.recordCount ) {
			messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ objectName  ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
		}

		prc.record = queryRowToStruct( prc.record );
		prc.recordLabel = prc.sourceRecord[ presideObjectService.getObjectAttribute( objectName=object, attributeName="labelfield", defaultValue="label" ) ] ?: "";

		prc.canDelete = datamanagerService.isOperationAllowed( object, "delete" ) && hasCmsPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ object ] );
		prc.translations = multilingualPresideObjectService.getTranslationStatus( object, id );
		prc.formName = "preside-objects.#translationObjectName#.admin.edit";

		_addObjectNameBreadCrumb( event, object );
		_addViewRecordBreadCrumb( event, object, id );
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:datamanager.translaterecord.breadcrumb.title", data=[ prc.language.name ] )
			, link  = ""
		);
		if( isTrue( fromDataGrid ) ) {
			prc.cancelAction     = event.buildAdminLink( linkTo="datamanager.object", querystring='id=#object#' );
			prc.formAction       = event.buildAdminLink( linkTo="datamanager.translateRecordAction", querystring='fromDataGrid=#fromDataGrid#' );
			prc.translateUrlBase = event.buildAdminLink( linkTo="datamanager.translateRecord", queryString="object=#object#&id=#id#&fromDataGrid=#fromDataGrid#&language=" );
		}
		prc.pageIcon  = "pencil";
		prc.pageTitle = translateResource( uri="cms:datamanager.translaterecord.title", data=[ objectName, prc.recordLabel, prc.language.name ] );
	}

	public void function translateRecordAction( event, rc, prc ) {
		var id                    = rc.id           ?: "";
		var object                = rc.object       ?: "";
		var languageId            = rc.language     ?: "";
		var fromDataGrid          = rc.fromDataGrid ?: "";
		var translationObjectName = multilingualPresideObjectService.getTranslationObjectName( object );
		var isDraft               = false;

		_checkObjectExists( argumentCollection=arguments, object=object );
		_checkPermission( argumentCollection=arguments, key="translate", object=object );

		var draftsEnabled = dataManagerService.areDraftsEnabledForObject( object );
		if ( draftsEnabled ) {
			isDraft = ( rc._saveaction ?: "" ) != "publish";

			if ( isDraft  ) {
				_checkPermission( argumentCollection=arguments, key="savedraft", object=object );
			} else {
				_checkPermission( argumentCollection=arguments, key="publish", object=object );
			}
		}

		prc.language = multilingualPresideObjectService.getLanguage( rc.language ?: "" );
		if ( prc.language.isempty() ) {
			messageBox.error( translateResource( uri="cms:multilingual.language.not.active.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.editRecord", queryString="object=#object#&id=#id#" ) );
		}

		var record = presideObjectService.selectData( objectName=object, filter={ id=id } );
		if ( !record.recordCount ) {
			messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ objectName  ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
		}

		var formName         = "preside-objects.#translationObjectName#.admin.edit";
		var version          = rc.version ?: "";
		var formData         = event.getCollectionForForm( formName=formName, stripPermissionedFields=true, permissionContext=object, permissionContextKeys=[] );
		var objectName       = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );

		var obj              = "";
		var persist          = "";

		formData._translation_language = languageId;
		formData.id = multilingualPresideObjectService.getExistingTranslationId(
			  objectName   = object
			, id           = id
			, languageId   = languageId
		);

		var validationResult = validateForm( formName=formName, formData=formData, stripPermissionedFields=true, permissionContext=object, permissionContextKeys=[] );

		if ( not validationResult.validated() ) {
			messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;
			persist.delete( "id" );
			if( isTrue( fromDataGrid ) ) {
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.translateRecord", querystring="id=#id#&object=#object#&fromDataGrid=true&version=#version#&language=#languageId#" ), persistStruct=persist );
			} else {
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.translateRecord", querystring="id=#id#&object=#object#&version=#version#&language=#languageId#" ), persistStruct=persist );
			}
		}

		multilingualPresideObjectService.saveTranslation(
			  objectName = object
			, id         = id
			, data       = formData
			, languageId = languageId
			, isDraft    = isDraft
		);

		var auditAction = "datamanager_translate_record";
		var auditDetail = QueryRowToStruct( record );
		auditDetail.append( { objectName=object, languageId=languageId } );
		if ( draftsEnabled ) {
			if ( isDraft ) {
				auditAction = "datamanager_save_draft_translation";
			} else {
				auditAction = "datamanager_publish_translation";
			}
		}

		event.audit(
			  action   = auditAction
			, type     = "datamanager"
			, recordId = id
			, detail   = auditDetail
		);

		messageBox.info( translateResource( uri="cms:datamanager.recordTranslated.confirmation", data=[ objectName ] ) );
		if( isTrue( fromDataGrid ) ) {
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", queryString="id=#object#" ) );
		} else {
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.editRecord", queryString="object=#object#&id=#id#" ) );
		}
	}

	public void function multiRecordAction( event, rc, prc ) {
		var object     = rc.object      ?: "";
		var action     = rc.multiAction ?: "";
		var ids        = rc.id          ?: "";
		var listingUrl = event.buildAdminLink( linkTo=rc.postAction ?: "datamanager.object", queryString="id=#object#" );

		_checkObjectExists( argumentCollection=arguments, object=object );

		if ( not Len( Trim( ids ) ) ) {
			messageBox.error( translateResource( "cms:datamanager.norecordsselected.error" ) );
			setNextEvent( url=listingUrl );
		}

		switch( action ){
			case "batchUpdate":
				setNextEvent(
					  url           = event.buildAdminLink( linkTo="datamanager.batchEditField", queryString="object=#object#&field=#( rc.field ?: '' )#" )
					, persistStruct = { id = ids }
				);
			break;
			case "delete":
				return deleteRecordAction( argumentCollection = arguments );
			break;
		}

		messageBox.error( translateResource( "cms:datamanager.invalid.multirecord.action.error" ) );
		setNextEvent( url=listingUrl );
	}

	public void function multiOneToManyRecordAction( event, rc, prc ) {
		var object          = rc.object          ?: "";
		var parentId        = rc.parentId        ?: "";
		var relationshipKey = rc.relationshipKey ?: "";
		var action          = rc.multiAction     ?: "";
		var ids             = rc.id              ?: "";
		var listingUrl      = event.buildAdminLink( linkTo=rc.postAction ?: "datamanager.manageOneToManyRecords", queryString="object=#object#&parentId=#parentId#&relationshipKey=#relationshipKey#" );

		_checkObjectExists( argumentCollection=arguments, object=object );

		if ( not Len( Trim( ids ) ) ) {
			messageBox.error( translateResource( "cms:datamanager.norecordsselected.error" ) );
			setNextEvent( url=listingUrl );
		}

		switch( action ){
			case "delete":
				return deleteOneToManyRecordAction( argumentCollection = arguments );
			break;
		}

		messageBox.error( translateResource( "cms:datamanager.invalid.multirecord.action.error" ) );
		setNextEvent( url=listingUrl );
	}


	public void function manageOneToManyRecords( event, rc, prc ) {
		var objectName = rc.object ?: "";

		_checkObjectExists( argumentCollection=arguments, object=objectName );

		var parentDetails = _getParentDetailsForOneToManyActions( event, rc, prc );
		var objectTitle   = translateResource( "preside-objects.#objectName#:title" );

		prc.gridFields    = _getObjectFieldsForGrid( objectName );
		prc.canAdd        = datamanagerService.isOperationAllowed( objectName, "add" );
		prc.delete        = datamanagerService.isOperationAllowed( objectName, "delete" );
		prc.pageTitle     = translateResource( uri="cms:datamanager.oneToManyListing.page.title"   , data=[ objectTitle, parentDetails.parentObjectTitle, parentDetails.parentRecordLabel ] );
		prc.pageSubTitle  = translateResource( uri="cms:datamanager.oneToManyListing.page.subtitle", data=[ objectTitle, parentDetails.parentObjectTitle, parentDetails.parentRecordLabel ] );
		prc.pageIcon      = "puzzle-piece";

		event.setLayout( "adminModalDialog" );
	}

	public void function addOneToManyRecord( event, rc, prc ) {
		var objectName = event.getValue( name="object", defaultValue="" );

		_checkObjectExists( argumentCollection=arguments, object=objectName );
		if ( !datamanagerService.isOperationAllowed( objectName, "add"   ) ) {
			event.adminAccessDenied();
		}

		var parentDetails = _getParentDetailsForOneToManyActions( event, rc, prc );
		var objectTitle   = translateResource( "preside-objects.#objectName#:title.singular" );

		prc.pageTitle     = translateResource( uri="cms:datamanager.oneToMany.addRecord.page.title"   , data=[ objectTitle, parentDetails.parentObjectTitle, parentDetails.parentRecordLabel ] );
		prc.pageSubTitle  = translateResource( uri="cms:datamanager.oneToMany.addRecord.page.subtitle", data=[ objectTitle, parentDetails.parentObjectTitle, parentDetails.parentRecordLabel ] );
		prc.pageIcon      = "plus";

		event.setLayout( "adminModalDialog" );
	}

	public void function editOneToManyRecord( event, rc, prc ) {
		var object          = rc.object          ?: "";
		var parentId        = rc.parentId        ?: "";
		var relationshipKey = rc.relationshipKey ?: "";
		var id              = rc.id              ?: "";
		var version         = rc.version         ?: "";
		var objectName      = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );

		_checkObjectExists( argumentCollection=arguments, object=object );
		if ( !datamanagerService.isOperationAllowed( object, "edit"   ) ) {
			event.adminAccessDenied();
		}

		prc.record = presideObjectService.selectData( objectName=object, filter={ id=id }, useCache=false );
		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ objectName  ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.manageOneToManyRecords", querystring="object=#object#&parentId=#parentId#&relationshipKey=#relationshipKey#" ) );
		}
		prc.record = queryRowToStruct( prc.record );
		prc.recordLabel = prc.record[ presideObjectService.getObjectAttribute( objectName=object, attributeName="labelfield", defaultValue="label" ) ] ?: "";

		var parentDetails = _getParentDetailsForOneToManyActions( event, rc, prc );

		prc.pageTitle     = translateResource( uri="cms:datamanager.oneToMany.editRecord.page.title"   , data=[ objectName, prc.recordLabel, parentDetails.parentObjectTitle, parentDetails.parentRecordLabel ] );
		prc.pageSubTitle  = translateResource( uri="cms:datamanager.oneToMany.editRecord.page.subtitle", data=[ objectName, prc.recordLabel, parentDetails.parentObjectTitle, parentDetails.parentRecordLabel ] );
		prc.pageIcon      = "pencil";

		event.setLayout( "adminModalDialog" );
	}

	public void function editOneToManyRecordAction( event, rc, prc ) {
		var id              = rc.id              ?: "";
		var object          = rc.object          ?: "";
		var parentId        = rc.parentId        ?: "";
		var relationshipKey = rc.relationshipKey ?: "";

		rc[ relationshipKey ] = parentId;

		_checkObjectExists( argumentCollection=arguments, object=object );
		if ( !datamanagerService.isOperationAllowed( object, "edit"   ) ) {
			event.adminAccessDenied();
		}

		runEvent(
			  event          = "admin.DataManager._editRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  errorUrl   = event.buildAdminLink( linkTo="datamanager.editOneToManyRecord"   , queryString="object=#object#&parentId=#parentId#&relationshipKey=#relationshipKey#&id=#id#" )
				, successUrl = event.buildAdminLink( linkTo="datamanager.manageOneToManyRecords", queryString="object=#object#&parentId=#parentId#&relationshipKey=#relationshipKey#" )
				, audit      = true
			}
		);
	}

	public void function sortRecords( event, rc, prc ) {
		var object           = rc.object  ?: "";
		var objectName       = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
		var objectNamePlural = translateResource( uri="preside-objects.#object#:title", defaultValue=object );

		if ( ! datamanagerService.isSortable( object ) ) {
			messageBox.error( translateResource( uri="cms:datamanager.objectNotSortable.error", data=[ objectName  ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
		}

		_checkObjectExists( argumentCollection=arguments, object=object );
		_objectCanBeViewedInDataManager( event=event, objectName=object, relocateIfNoAccess=true );
		_checkPermission( argumentCollection=arguments, key="edit", object=object );

		prc.records = datamanagerService.getRecordsForSorting( objectName=object );

		_addObjectNameBreadCrumb( event, object );
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:datamanager.sortRecords.breadcrumb.title" )
			, link  = ""
		);
		prc.pageTitle = translateResource( uri="cms:datamanager.sortRecords.title", data=[ objectNamePlural ] );
		prc.pageIcon  = "sort-amount-asc";
	}

	public void function sortRecordsAction( event, rc, prc ) {
		var object           = rc.object  ?: "";
		var objectName       = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
		var objectNamePlural = translateResource( uri="preside-objects.#object#:title", defaultValue=object );

		if ( ! datamanagerService.isSortable( object ) ) {
			messageBox.error( translateResource( uri="cms:datamanager.objectNotSortable.error", data=[ objectName  ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
		}

		_checkObjectExists( argumentCollection=arguments, object=object );
		_objectCanBeViewedInDataManager( event=event, objectName=object, relocateIfNoAccess=true );
		_checkPermission( argumentCollection=arguments, key="edit", object=object );

		datamanagerService.saveSortedRecords(
			  objectName = object
			, sortedIds  = ListToArray( rc.ordered ?: "" )
		);

		messageBox.info( translateResource( uri="cms:datamanager.recordsSorted.confirmation", data=[ objectName  ] ) );
		setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
	}

	public void function dataExportConfigModal( event, rc, prc ) {
		if ( !isFeatureEnabled( "dataexport" ) ) {
			event.notFound();
		}
		var args   = {};

		args.objectName = rc.id ?: "";
		args.objectTitle = translateResource( uri="preside-objects.#args.objectName#:title", defaultValue=args.objectName );
		args.defaultExportFilename = translateresource(
			  uri  = "cms:dataexport.config.form.field.title.default"
			, data = [ args.objectTitle, DateTimeFormat( Now(), 'yyyy-mm-dd HH:nn' ) ]
		);

		event.setView( view="/admin/datamanager/dataExportConfigModal", layout="adminModalDialog", args=args );
	}

	public void function exportDataAction( event, rc, prc ) {
		if ( !isFeatureEnabled( "dataexport" ) ) {
			event.notFound();
		}

		var objectName = rc.object ?: "";

		_checkObjectExists( argumentCollection=arguments, object=objectName );
		_checkPermission( argumentCollection=arguments, key="read", object=objectName, checkOperations=false );

		runEvent(
			  event          = "admin.DataManager._exportDataAction"
			, prePostExempt  = true
			, private        = true
		);
	}

<!--- VIEWLETS --->
	private string function versionNavigator( event, rc, prc, args={} ) {
		var selectedVersion = Val( args.version ?: "" );
		var objectName      = args.object ?: "";
		var id              = args.id     ?: "";

		args.latestVersion          = versioningService.getLatestVersionNumber( objectName=objectName, recordId=id );
		args.latestPublishedVersion = versioningService.getLatestVersionNumber( objectName=objectName, recordId=id, publishedOnly=true );
		args.versions               = presideObjectService.getRecordVersions(
			  objectName = objectName
			, id         = id
		);

		if ( !selectedVersion ) {
			selectedVersion = args.latestVersion;
		}

		args.isLatest    = args.latestVersion == selectedVersion;
		args.nextVersion = 0;
		args.prevVersion = args.versions.recordCount < 2 ? 0 : args.versions._version_number[ args.versions.recordCount-1 ];

		for( var i=1; i <= args.versions.recordCount; i++ ){
			if ( args.versions._version_number[i] == selectedVersion ) {
				args.nextVersion = i > 1 ? args.versions._version_number[i-1] : 0;
				args.prevVersion = i < args.versions.recordCount ? args.versions._version_number[i+1] : 0;
			}
		}

		return renderView( view="admin/datamanager/versionNavigator", args=args );
	}

	private string function translationVersionNavigator( event, rc, prc, args={} ) {
		var recordId              = args.id       ?: "";
		var language              = args.language ?: "";
		var translationObjectName = multilingualPresideObjectService.getTranslationObjectName( args.object ?: "" );
		var selectedVersion       = Val( args.version ?: "" );
		var existingTranslation = multilingualPresideObjectService.selectTranslation(
			  objectName   = args.object ?: ""
			, id           = args.id ?: ""
			, languageId   = args.language ?: ""
			, selectFields = [ "id" ]
			, version      = selectedVersion
		);

		if ( !existingTranslation.recordCount ) {
			return "";
		}

		args.version  = args.version ?: selectedVersion;
		args.latestVersion          = versioningService.getLatestVersionNumber(
			  objectName = translationObjectName
			, filter     = { _translation_source_record=recordId, _translation_language=language }
		);
		args.latestPublishedVersion = versioningService.getLatestVersionNumber(
			  objectName    = translationObjectName
			, filter        = { _translation_source_record=recordId, _translation_language=language }
			, publishedOnly = true
		);
		args.versions = presideObjectService.getRecordVersions(
			  objectName = translationObjectName
			, id         = existingTranslation.id
		);

		if ( !selectedVersion && args.versions.recordCount ) {
			selectedVersion = args.latestVersion;
		}

		args.isLatest    = args.latestVersion == selectedVersion;
		args.nextVersion = 0;
		args.prevVersion = args.versions.recordCount < 2 ? 0 : args.versions._version_number[ args.versions.recordCount-1 ];

		for( var i=1; i <= args.versions.recordCount; i++ ){
			if ( args.versions._version_number[i] == selectedVersion ) {
				args.nextVersion = i > 1 ? args.versions._version_number[i-1] : 0;
				args.prevVersion = i < args.versions.recordCount ? args.versions._version_number[i+1] : 0;
			}
		}

		args.baseUrl        = args.baseUrl        ?: event.buildAdminLink( linkTo='datamanager.translateRecord'         , queryString='object=#args.object#&id=#args.id#&language=#language#&version=' );
		args.allVersionsUrl = args.allVersionsUrl ?: event.buildAdminLink( linkTo='datamanager.translationRecordHistory', queryString='object=#args.object#&id=#args.id#&language=#language#' );

		return renderView( view="admin/datamanager/versionNavigator", args=args );
	}

<!--- private events for sharing --->
	private void function _getObjectRecordsForAjaxDataTables(
		  required any     event
		, required struct  rc
		, required struct  prc
		,          string  object          = ( rc.id ?: '' )
		,          string  gridFields      = ( rc.gridFields ?: 'label,datecreated,_version_author' )
		,          string  actionsView     = ""
		,          string  orderBy         = ""
		,          struct  filter          = {}
		,          boolean useMultiActions = true
		,          boolean isMultilingual  = false
		,          boolean draftsEnabled   = false
		,          array   extraFilters    = []
		,          array   searchFields

	) {
		gridFields = ListToArray( gridFields );

		var objectTitleSingular = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
		var objectIsVersioned   = presideObjectService.objectIsVersioned( object );
		var checkboxCol         = [];
		var optionsCol          = [];
		var statusCol           = [];
		var translateStatusCol  = [];
		var translations        = [];
		var translateUrlBase    = "";
		var getRecordsArgs      = {};
		var excludedArguments   = [ "event", "rc", "prc", "actionsView", "useMultiActions", "isMultilingual", "object" ];

		for( var argument in arguments ) {
			if ( !excludedArguments.find( argument ) ) {
				getRecordsArgs[ argument ] = duplicate( arguments[ argument ] );
			}
		}

		getRecordsArgs.objectName    = arguments.object;
		getRecordsArgs.startRow      = dtHelper.getStartRow();
		getRecordsArgs.maxRows       = dtHelper.getMaxRows();
		getRecordsArgs.orderBy       = dtHelper.getSortOrder();
		getRecordsArgs.searchQuery   = dtHelper.getSearchQuery();

		if ( Len( Trim( rc.sFilterExpression ?: "" ) ) ) {
			try {
				getRecordsArgs.extraFilters.append( rulesEngineFilterService.prepareFilter(
					  objectName = object
					, expressionArray = DeSerializeJson( rc.sFilterExpression ?: "" )
				) );
			} catch( any e ){}
		}

		if ( Len( Trim( rc.sSavedFilterExpressions ?: "" ) ) ) {
			var savedFilters = presideObjectService.selectData(
				  objectName   = "rules_engine_condition"
				, selectFields = [ "expressions" ]
				, filter       = { id=ListToArray( rc.sSavedFilterExpressions ?: "" ) }
			);

			for( var filter in savedFilters ) {
				try {
					getRecordsArgs.extraFilters.append( rulesEngineFilterService.prepareFilter(
						  objectName      = object
						, expressionArray = DeSerializeJson( filter.expressions )
					) );
				} catch( any e ){}
			}
		}

		if ( IsEmpty( getRecordsArgs.orderBy ) ) {
			getRecordsArgs.orderBy = arguments.orderBy.len() ? arguments.orderBy : dataManagerService.getDefaultSortOrderForDataGrid( object );
		}

		var results = dataManagerService.getRecordsForGridListing( argumentCollection=getRecordsArgs );
		var records = Duplicate( results.records );

		if ( !actionsView.trim().len() ) {
			var viewRecordLink    = event.buildAdminLink( objectName=object, recordId="{id}" );
			var editRecordLink    = event.buildAdminLink( linkTo="datamanager.editRecord", queryString="object=#object#&id={id}&resultAction=grid" );
			var deleteRecordLink  = event.buildAdminLink( linkTo="datamanager.deleteRecordAction", queryString="object=#object#&id={id}" );
			var viewHistoryLink   = event.buildAdminLink( linkTo="datamanager.recordHistory", queryString="object=#object#&id={id}" );
			var canView           = datamanagerService.isOperationAllowed( object, "read"   );
			var canEdit           = datamanagerService.isOperationAllowed( object, "edit"   ) && hasCmsPermission( permissionKey="datamanager.edit", context="datamanager", contextKeys=[ object ] );
			var canDelete         = datamanagerService.isOperationAllowed( object, "delete" ) && hasCmsPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ object ] );
			var canViewHistory    = objectIsVersioned && datamanagerService.isOperationAllowed( object, "viewversions" ) && hasCmsPermission( permissionKey="datamanager.viewversions", context="datamanager", contextKeys=[ object ] );
		}

		for( var record in records ){
			for( var field in gridFields ){
				records[ field ][ records.currentRow ] = renderField( object, field, record[ field ], [ "adminDataTable", "admin" ] );
			}

			if ( useMultiActions ) {
				ArrayAppend( checkboxCol, renderView( view="/admin/datamanager/_listingCheckbox", args={ recordId=record.id } ) );
			}

			if ( actionsView.trim().len() ) {
				var actionsViewlet = Replace( ReReplace( actionsView, "^/", "" ), "/", ".", "all" );
				var viewletArgs    = Duplicate( record );
				viewletArgs.objectName = object;

				ArrayAppend( optionsCol, renderViewlet( event=actionsViewlet, args=viewletArgs ) );
			} else {
				ArrayAppend( optionsCol, renderView( view="/admin/datamanager/_listingActions", args={
					  viewRecordLink    = viewRecordLink.replace( "{id}", record.id )
					, editRecordLink    = editRecordLink.replace( "{id}", record.id )
					, deleteRecordLink  = deleteRecordLink.replace( "{id}", record.id )
					, deleteRecordTitle = translateResource( uri="cms:datamanager.deleteRecord.prompt", data=[ objectTitleSingular, record[ gridFields[1] ] ] )
					, viewHistoryLink   = viewHistoryLink.replace( "{id}", record.id )
					, canView           = canView
					, canEdit           = canEdit
					, canDelete         = canDelete
					, canViewHistory    = canViewHistory
					, objectName        = object
				} ) );
			}

			if ( isMultilingual ) {
				translations     = multilingualPresideObjectService.getTranslationStatus( object, record.id );
				translateUrlBase = event.buildAdminLink( linkTo="datamanager.translateRecord", queryString="object=#object#&id=#record.id#&fromDataGrid=true&language=" );
				ArrayAppend( translateStatusCol, renderView( view="/admin/datamanager/_listingTranslations", args={
					  translations     = translations
					, translateUrlBase = translateUrlBase
				} ) );
			}

			if ( draftsEnabled ) {
				statusCol.append( renderView( view="/admin/datamanager/_recordStatus", args=record ) );
			}
		}

		if ( draftsEnabled ) {
			QueryAddColumn( records, "_status" , statusCol );
			ArrayAppend( gridFields, "_status" );
		}
		if ( isMultilingual ) {
			QueryAddColumn( records, "_translateStatus" , translateStatusCol );
			ArrayAppend( gridFields, "_translateStatus" );
		}
		if ( useMultiActions ) {
			QueryAddColumn( records, "_checkbox", checkboxCol );
			ArrayPrepend( gridFields, "_checkbox" );
		}

		QueryAddColumn( records, "_options" , optionsCol );
		ArrayAppend( gridFields, "_options" );

		event.renderData( type="json", data=dtHelper.queryToResult( records, gridFields, results.totalRecords ) );
	}

	private void function _getRecordHistoryForAjaxDataTables(
		  required any     event
		, required struct  rc
		, required struct  prc
		,          string  object      = ( rc.object   ?: '' )
		,          string  recordId    = ( rc.id       ?: '' )
		,          string  property    = ( rc.property ?: '' )
		,          string  actionsView = ""
	) {
		var versionObject       = presideObjectService.getVersionObjectName( object );
		var objectTitleSingular = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
		var optionsCol          = [];
		var results             = dataManagerService.getRecordHistoryForGridListing(
			  objectName  = object
			, recordId    = recordId
			, property    = property
			, startRow    = dtHelper.getStartRow()
			, maxRows     = dtHelper.getMaxRows()
			, orderBy     = dtHelper.getSortOrder()
			, searchQuery = dtHelper.getSearchQuery()
		);
		var records    = Duplicate( results.records );
		var gridFields = [ "published", "datemodified", "_version_author", "_version_changed_fields" ];
		var canView    = datamanagerService.isOperationAllowed( object, "read"   );
		var canEdit    = datamanagerService.isOperationAllowed( object, "edit"   ) && hasCmsPermission( permissionKey="datamanager.edit", context="datamanager", contextKeys=[ object ] );

		for( var record in records ){
			for( var field in gridFields ){
				if ( field == "published" ) {
					records[ field ][ records.currentRow ] = renderContent( "boolean", record[ field ], [ "adminDataTable", "admin" ] );
				} else if ( field == "_version_changed_fields" ) {
					var rendered = [];
					for( var changedField in ListToArray( records[ field ][ records.currentRow ] ) ) {
						var translated = translateResource(
							  uri          = "preside-objects.#object#:field.#changedField#.title"
							, defaultValue = translateResource( uri="cms:preside-objects.default.field.#changedField#.title", defaultValue="" )
						);
						if ( Len( Trim( translated ) ) ) {
							rendered.append( translated );
						}
					}
					records[ field ][ records.currentRow ] = '<span title="#HtmlEditFormat( rendered.toList( ', ' ) )#">' & abbreviate( rendered.toList( ", " ), 100 ) & '</span>';
				} else {
					records[ field ][ records.currentRow ] = renderField( versionObject, field, record[ field ], [ "adminDataTable", "admin" ] );
				}
			}

			if ( Len( Trim( actionsView ) ) ) {
				ArrayAppend( optionsCol, renderView( view=actionsView, args=record ) );
			} else {
				ArrayAppend( optionsCol, renderView( view="/admin/datamanager/_historyActions", args={
					  objectName     = object
					, recordId       = recordId
					, canEdit        = canEdit
					, canView        = canView
					, viewRecordLink = event.buildAdminLink( linkTo="datamanager.viewRecord", queryString="object=#object#&id=#record.id#&version=#record._version_number#" )
					, editRecordLink = event.buildAdminLink( linkTo="datamanager.editRecord", queryString="object=#object#&id=#record.id#&version=#record._version_number#" )
				} ) );
			}
		}

		QueryAddColumn( records, "_options" , optionsCol );
		ArrayAppend( gridFields, "_options" );

		event.renderData( type="json", data=dtHelper.queryToResult( records, gridFields, results.totalRecords ) );
	}

	private void function _getTranslationRecordHistoryForAjaxDataTables(
		  required any    event
		, required struct rc
		, required struct prc
		,          string object      = ( rc.object   ?: '' )
		,          string recordId    = ( rc.id       ?: '' )
		,          string languageId  = ( rc.language ?: '' )
		,          string property    = ( rc.property ?: '' )
		,          string actionsView = ""
	) {
		gridFields = ListToArray( gridFields );

		var translationObject   = multilingualPresideObjectService.getTranslationObjectName( object );
		var translationRecord   = multilingualPresideObjectService.selectTranslation(
			  objectName   = object
			, id           = recordId
			, languageId   = languageId
			, selectFields = [ "id" ]
		);
		var versionObject       = presideObjectService.getVersionObjectName( translationObject );
		var objectTitleSingular = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
		var optionsCol          = [];
		var results             = dataManagerService.getRecordHistoryForGridListing(
			  objectName  = translationObject
			, recordId    = translationRecord.id ?: ""
			, property    = property
			, startRow    = dtHelper.getStartRow()
			, maxRows     = dtHelper.getMaxRows()
			, orderBy     = dtHelper.getSortOrder()
			, searchQuery = dtHelper.getSearchQuery()
			, filter      = { _translation_language = languageId }
		);
		var records = Duplicate( results.records );
		var gridFields = [ "published", "datemodified", "_version_author", "_version_changed_fields" ];

		for( var record in records ){
			for( var field in gridFields ){
				if ( field == "published" ) {
					records[ field ][ records.currentRow ] = renderContent( "boolean", record[ field ], [ "adminDataTable", "admin" ] );
				} else if ( field == "_version_changed_fields" ) {
					var rendered = [];
					for( var changedField in ListToArray( records[ field ][ records.currentRow ] ) ) {
						var translated = translateResource(
							  uri          = "preside-objects.#object#:field.#changedField#.title"
							, defaultValue = translateResource( uri="cms:preside-objects.default.field.#changedField#.title", defaultValue="" )
						);
						if ( Len( Trim( translated ) ) ) {
							rendered.append( translated );
						}
					}
					records[ field ][ records.currentRow ] = '<span title="#HtmlEditFormat( rendered.toList( ', ' ) )#">' & abbreviate( rendered.toList( ", " ), 100 ) & '</span>';
				} else {
					records[ field ][ records.currentRow ] = renderField( versionObject, field, record[ field ], [ "adminDataTable", "admin" ] );
				}
			}

			if ( Len( Trim( actionsView ) ) ) {
				ArrayAppend( optionsCol, renderView( view=actionsView, args=record ) );
			} else {
				ArrayAppend( optionsCol, renderView( view="/admin/datamanager/_historyActions", args={
					  objectName = object
					, recordId   = recordId
					, editRecordLink = event.buildAdminLink( linkTo="datamanager.translateRecord", queryString="object=#object#&id=#recordId#&language=#languageId#&version=#record._version_number#" )
				} ) );
			}
		}

		QueryAddColumn( records, "_options" , optionsCol );
		ArrayAppend( gridFields, "_options" );

		event.renderData( type="json", data=dtHelper.queryToResult( records, gridFields, results.totalRecords ) );
	}

	private any function _addRecordAction(
		  required any     event
		, required struct  rc
		, required struct  prc
		,          string  object                  = ( rc.object ?: '' )
		,          string  errorAction             = ""
		,          string  errorUrl                = ( errorAction.len() ? event.buildAdminLink( linkTo=errorAction ) : event.buildAdminLink( linkTo="datamanager.addRecord", querystring="object=#arguments.object#" ) )
		,          string  viewRecordAction        = ""
		,          string  viewRecordUrl           = event.buildAdminLink( linkTo=( viewRecordAction.len() ? viewRecordAction : "datamanager.viewRecord" ), querystring="object=#arguments.object#&id={newid}" )
		,          string  addAnotherAction        = ""
		,          string  addAnotherUrl           = ( addAnotherAction.len() ? event.buildAdminLink( linkTo=addAnotherAction ) : event.buildAdminLink( linkTo="datamanager.addRecord", querystring="object=#arguments.object#" ) )
		,          string  successAction           = ""
		,          string  successUrl              = ( successAction.len() ? event.buildAdminLink( linkTo=successAction, queryString='id={newid}' ) : event.buildAdminLink( linkTo="datamanager.object", querystring="id=#arguments.object#" ) )
		,          boolean redirectOnSuccess       = true
		,          string  formName                = "preside-objects.#arguments.object#.admin.add"
		,          string  mergeWithFormName       = ""
		,          boolean audit                   = false
		,          string  auditAction             = ""
		,          string  auditType               = "datamanager"
		,          boolean draftsEnabled           = false
		,          boolean canPublish              = false
		,          boolean canSaveDraft            = false
		,          boolean stripPermissionedFields = true
		,          string  permissionContext       = arguments.object
		,          array   permissionContextKeys   = []
		,          any     validationResult
	) {
		arguments.formName = Len( Trim( arguments.mergeWithFormName ) ) ? formsService.getMergedFormName( arguments.formName, arguments.mergeWithFormName ) : arguments.formName;
		var formData         = event.getCollectionForForm( formName=arguments.formName, stripPermissionedFields=arguments.stripPermissionedFields, permissionContext=arguments.permissionContext, permissionContextKeys=arguments.permissionContextKeys );
		var labelField       = presideObjectService.getObjectAttribute( object, "labelfield", "label" );
		var obj              = "";
		var validationResult = "";
		var newId            = "";
		var newRecordLink    = "";
		var persist          = "";
		var isDraft          = false;

		validationResult = validateForm( formName=arguments.formName, formData=formData, validationResult=( arguments.validationResult ?: NullValue() ), stripPermissionedFields=arguments.stripPermissionedFields, permissionContext=arguments.permissionContext, permissionContextKeys=arguments.permissionContextKeys );

		if ( not validationResult.validated() ) {
			messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;

			setNextEvent( url=errorUrl, persistStruct=persist );
		}

		if ( arguments.draftsEnabled ) {
			isDraft = ( rc._saveaction ?: "" ) != "publish";

			if ( isDraft && !arguments.canSaveDraft ) {
				event.adminAccessDenied();
			}
			if ( !isDraft && !arguments.canPublish ) {
				event.adminAccessDenied();
			}
		}

		obj = presideObjectService.getObject( object );
		newId = obj.insertData( data=formData, insertManyToManyRecords=true, isDraft=isDraft );

		if ( arguments.audit ) {
			var auditDetail = Duplicate( formData );
			auditDetail.id = newId;
			auditDetail.objectName = arguments.object;
			if ( arguments.auditAction == "" ) {
				if ( arguments.draftsEnabled && isDraft ) {
					arguments.auditAction = "datamanager_add_draft_record";
				} else {
					arguments.auditAction = "datamanager_add_record";
				}
			}
			event.audit(
				  action   = arguments.auditAction
				, type     = arguments.auditType
				, recordId = newId
				, detail   = auditDetail
			);
		}

		if ( !redirectOnSuccess ) {
			return newId;
		}

		newRecordLink = replaceNoCase( viewRecordUrl, "{newid}", newId, "all" );

		messageBox.info( translateResource( uri="cms:datamanager.recordAdded.confirmation", data=[
			  translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object )
			, '<a href="#newRecordLink#">#event.getValue( name=labelField, defaultValue=translateResource( uri="cms:datamanager.record" ) )#</a>'
		] ) );

		if ( Val( event.getValue( name="_addanother", defaultValue=0 ) ) ) {
			setNextEvent( url=addAnotherUrl, persist="_addAnother" );
		} else {
			setNextEvent( url=replaceNoCase( successUrl, "{newid}", newId, "all" ) );
		}
	}

	private any function _addOneToManyRecordAction(
		  required any     event
		, required struct  rc
		, required struct  prc
		,          string  object                  = ( rc.object          ?: '' )
		,          string  parentId                = ( rc.parentId        ?: '' )
		,          string  relationshipKey         = ( rc.relationshipKey ?: '' )
		,          string  errorAction             = ""
		,          string  viewRecordAction        = ""
		,          string  addAnotherAction        = ""
		,          string  successAction           = ""
		,          boolean redirectOnSuccess       = true
		,          string  formName                = "preside-objects.#arguments.object#.admin.add"
		,          boolean stripPermissionedFields = true
		,          string  permissionContext       = arguments.object
		,          array   permissionContextKeys   = []
	) {
		var formData         = event.getCollectionForForm( formName=arguments.formName, stripPermissionedFields=arguments.stripPermissionedFields, permissionContext=arguments.permissionContext, permissionContextKeys=arguments.permissionContextKeys );
		var labelField       = presideObjectService.getObjectAttribute( object, "labelfield", "label" );
		var obj              = "";
		var validationResult = "";
		var newId            = "";
		var newRecordLink    = "";
		var persist          = "";

		formData[ arguments.relationshipKey ] = arguments.parentId;

		validationResult = validateForm( formName=arguments.formName, formData=formData, stripPermissionedFields=arguments.stripPermissionedFields, permissionContext=arguments.permissionContext, permissionContextKeys=arguments.permissionContextKeys );

		if ( not validationResult.validated() ) {
			messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;
			if ( Len( errorAction ?: "" ) ) {
				setNextEvent( url=event.buildAdminLink( linkTo=errorAction ), persistStruct=persist );
			} else {
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.addOneToManyRecord", querystring="object=#object#&parentId=#arguments.parentId#&relationshipKey=#arguments.relationshipKey#" ), persistStruct=persist );
			}
		}

		obj = presideObjectService.getObject( object );
		newId = obj.insertData( data=formData, insertManyToManyRecords=true );

		if ( !redirectOnSuccess ) {
			return newId;
		}

		newRecordLink = event.buildAdminLink( linkTo=viewRecordAction ?: "datamanager.viewRecord", queryString="object=#object#&id=#newId#" );

		messageBox.info( translateResource( uri="cms:datamanager.recordAdded.confirmation", data=[
			  translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object )
			, '<a href="#newRecordLink#">#event.getValue( name=labelField, defaultValue=translateResource( uri="cms:datamanager.record" ) )#</a>'
		] ) );

		if ( Val( event.getValue( name="_addanother", defaultValue=0 ) ) ) {
			if ( Len( addAnotherAction ?: "" ) ) {
				setNextEvent( url=event.buildAdminLink( linkTo=addAnotherAction ), persist="_addAnother" );
			} else {
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.addOneToManyRecord", queryString="object=#object#&parentId=#arguments.parentId#&relationshipKey=#arguments.relationshipKey#" ), persist="_addAnother" );
			}
		} else {
			if ( Len( successAction ?: "" ) ) {
				setNextEvent( url=event.buildAdminLink( linkTo=successAction ) );
			} else {
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.manageOneToManyRecords", queryString="object=#object#&parentId=#arguments.parentId#&relationshipKey=#arguments.relationshipKey#" ) );
			}
		}
	}

	private void function _quickAddRecordAction(
		  required any     event
		, required struct  rc
		, required struct  prc
		,          string  object                  = ( rc.object ?: '' )
		,          string  formName                = "preside-objects.#arguments.object#.admin.quickadd"
		,          boolean stripPermissionedFields = true
		,          string  permissionContext       = arguments.object
		,          array   permissionContextKeys   = []

	) {
		var formData         = event.getCollectionForForm( formName=arguments.formName, stripPermissionedFields=arguments.stripPermissionedFields, permissionContext=arguments.permissionContext, permissionContextKeys=arguments.permissionContextKeys );
		var validationResult = validateForm( formName=arguments.formName, formData=formData, stripPermissionedFields=arguments.stripPermissionedFields, permissionContext=arguments.permissionContext, permissionContextKeys=arguments.permissionContextKeys );

		if ( validationResult.validated() ) {
			var obj = presideObjectService.getObject( object );
			var newId = obj.insertData( data=formData, insertManyToManyRecords=true );

			event.renderData( type="json", data={
				  success  = true
				, recordId = newId
			});
		} else {
			event.renderData( type="json", data={
				  success          = false
				, validationResult = translateValidationMessages( validationResult )
			});
		}
	}

	private void function _deleteRecordAction(
		  required any     event
		, required struct  rc
		, required struct  prc
		,          string  object            = ( rc.object ?: '' )
		,          string  postAction        = "datamanager.object"
		,          string  postActionUrl     = ( rc.postActionUrl ?: ( event.buildAdminLink( linkTo=postAction, queryString=( postAction=="datamanager.object" ? "id=#object#" : "" ) ) ) )
		,          string  cancelUrl         = cgi.http_referer
		,          boolean redirectOnSuccess = true
		,          boolean audit             = false
		,          string  auditAction       = "datamanager_delete_record"
		,          string  auditType         = "datamanager"
	) {
		var id               = rc.id          ?: "";
		var forceDelete      = rc.forceDelete ?: false;
		var ids              = ListToArray( id );
		var obj              = "";
		var records          = "";
		var record           = "";
		var blockers         = "";
		var objectName       = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
		var objectNamePlural = translateResource( uri="preside-objects.#object#:title", defaultValue=object );
		var labelField       = presideObjectService.getObjectAttribute( object, "labelfield", "label" );

		obj = presideObjectService.getObject( object );

		if ( !Len( labelField ) ) {
			labelField = "id";
		} else {
			try {
				presideObjectService.getObjectProperty( object, labelField );
			} catch ( any e ) {
				labelField = "id";
			}
		}

		records = obj.selectData( selectFields=[ "id", labelField ], filter={ id = ids }, useCache=false );

		if ( records.recordCount neq ids.len() ) {
			messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[objectName] ) );
			setNextEvent( url=postActionUrl );
		}

		if ( not IsBoolean( forceDelete ) or not forceDelete ) {
			blockers = presideObjectService.listForeignObjectsBlockingDelete( object, ids );

			if ( ArrayLen( blockers ) ) {
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.cascadeDeletePrompt", queryString="object=#object#" ), persistStruct={ blockers = blockers, id=ArrayToList(ids), postActionUrl=postActionUrl, cancelUrl=cancelUrl } );
			}
		} else {
			try {
				presideObjectService.deleteRelatedData( objectName=object, recordId=ids );
			} catch( "PresideObjectService.CascadeDeleteTooDeep" e ) {
				messageBox.error( translateResource( uri="cms:datamanager.cascadeDelete.cascade.too.deep.error", data=[objectName] ) );
				setNextEvent( url=postActionUrl );
			}
		}

		if ( presideObjectService.deleteData( objectName=object, filter={ id = ids } ) ) {
			for( record in records ) {
				if ( arguments.audit ) {
					var auditDetail = Duplicate( record );
					auditDetail.objectName = object;
					event.audit(
						  action   = arguments.auditAction
						, type     = arguments.auditType
						, recordId = record.id
						, detail   = auditDetail
					);
				}
			}

			if ( redirectOnSuccess ) {
				if ( ids.len() eq 1 ) {
					messageBox.info( translateResource( uri="cms:datamanager.recordDeleted.confirmation", data=[ objectName, records[labelField][1] ] ) );
				} else {
					messageBox.info( translateResource( uri="cms:datamanager.recordsDeleted.confirmation", data=[ objectNamePlural, ids.len() ] ) );
				}

				setNextEvent( url=postActionUrl );
			}
		} else {
			messageBox.error( translateResource( uri="cms:datamanager.recordNotDeleted.unknown.error" ) );
			setNextEvent( url=postActionUrl );
		}
	}

	private void function _editRecordAction(
		  required any     event
		, required struct  rc
		, required struct  prc
		,          string  object                  = ( rc.object ?: '' )
		,          string  recordId                = ( rc.id     ?: '' )
		,          string  errorAction             = ""
		,          string  errorUrl                = ( errorAction.len() ? event.buildAdminLink( linkTo=errorAction ) : event.buildAdminLink( linkTo="datamanager.editRecord", querystring="object=#arguments.object#&id=#arguments.recordId#" ) )
		,          string  missingUrl              = event.buildAdminLink( linkTo="datamanager.object", querystring="id=#arguments.object#" )
		,          string  successAction           = ""
		,          string  successUrl              = ( successAction.len() ? event.buildAdminLink( linkTo=successAction, queryString='id=' & id ) : event.buildAdminLink( linkTo="datamanager.object", querystring="id=#arguments.object#" ) )
		,          boolean redirectOnSuccess       = true
		,          string  formName                = "preside-objects.#object#.admin.edit"
		,          string  mergeWithFormName       = ""
		,          boolean audit                   = false
		,          string  auditAction             = ""
		,          string  auditType               = "datamanager"
		,          boolean draftsEnabled           = false
		,          boolean canPublish              = false
		,          boolean canSaveDraft            = false
		,          boolean stripPermissionedFields = true
		,          string  permissionContext       = arguments.object
		,          array   permissionContextKeys   = []
		,          any     validationResult
	) {
		arguments.formName = Len( Trim( mergeWithFormName ) ) ? formsService.getMergedFormName( formName, mergeWithFormName ) : formName;

		var id               = rc.id      ?: "";
		var version          = rc.version ?: "";
		var formData         = event.getCollectionForForm( formName=arguments.formName, stripPermissionedFields=arguments.stripPermissionedFields, permissionContext=arguments.permissionContext, permissionContextKeys=arguments.permissionContextKeys );
		var objectName       = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
		var obj              = "";
		var validationResult = "";
		var persist          = "";
		var isDraft          = false;
		var forceVersion     = false;
		var existingRecord   = presideObjectService.selectData( objectName=object, filter={ id=id }, allowDraftVersions=arguments.draftsEnabled );

		if ( !existingRecord.recordCount ) {
			messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ objectName  ] ) );

			setNextEvent( url=missingUrl );
		}

		formData.id = id;
		validationResult = validateForm( formName=formName, formData=formData, validationResult=( arguments.validationResult ?: NullValue() ), stripPermissionedFields=arguments.stripPermissionedFields, permissionContext=arguments.permissionContext, permissionContextKeys=arguments.permissionContextKeys );

		if ( not validationResult.validated() ) {
			messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
			persist = formData;
			persist.validationResult = validationResult;

			setNextEvent( url=errorUrl, persistStruct=persist );
		}

		if ( arguments.draftsEnabled ) {
			isDraft = ( rc._saveaction ?: "" ) != "publish";

			if ( isDraft && !arguments.canSaveDraft ) {
				event.adminAccessDenied();
			}
			if ( !isDraft && !arguments.canPublish ) {
				event.adminAccessDenied();
			}

			if ( !isDraft ) {
				forceVersion = IsTrue( existingRecord._version_is_draft ) || IsTrue( existingRecord._version_has_drafts );
			}
		}

		presideObjectService.updateData(
			  id                      = id
			, objectName              = object
			, data                    = formData
			, updateManyToManyRecords = true
			, isDraft                 = isDraft
			, forceVersionCreation    = forceVersion
		);

		if ( arguments.audit ) {
			var auditDetail = Duplicate( formData );
			auditDetail.objectName = arguments.object;
			if ( !Len( Trim( arguments.auditAction ) ) ) {
				if ( arguments.draftsEnabled ) {
					if ( isDraft ) {
						arguments.auditAction = "datamanager_save_draft_record";
					} else {
						arguments.auditAction = "datamanager_publish_record";
					}
				} else {
					arguments.auditAction = "datamanager_edit_record";
				}
			}
			event.audit(
				  action   = arguments.auditAction
				, type     = arguments.auditType
				, recordId = id
				, detail   = auditDetail
			);
		}

		if ( redirectOnSuccess ) {
			messageBox.info( translateResource( uri="cms:datamanager.recordEdited.confirmation", data=[ objectName ] ) );

			setNextEvent( url=successUrl );
		}
	}

	private void function _quickEditRecordAction(
		  required any     event
		, required struct  rc
		, required struct  prc
		,          string  object                  = ( rc.object ?: '' )
		,          string  formName                = "preside-objects.#arguments.object#.admin.quickedit"
		,          boolean stripPermissionedFields = true
		,          string  permissionContext       = arguments.object
		,          array   permissionContextKeys   = []

	) {
		var id               = rc.id      ?: "";
		var formData         = event.getCollectionForForm( formName=arguments.formName, stripPermissionedFields=arguments.stripPermissionedFields, permissionContext=arguments.permissionContext, permissionContextKeys=arguments.permissionContextKeys );
		var validationResult = "";

		if ( presideObjectService.dataExists( objectName=arguments.object, filter={ id=id } ) ) {
			formData.id = id;
			validationResult = validateForm( formName=arguments.formName, formData=formData, stripPermissionedFields=arguments.stripPermissionedFields, permissionContext=arguments.permissionContext, permissionContextKeys=arguments.permissionContextKeys );

			if ( validationResult.validated() ) {
				presideObjectService.updateData( objectName=object, data=formData, id=id, updateManyToManyRecords=true );
				event.renderData( type="json", data={ success  = true } );
			} else {
				event.renderData( type="json", data={
					  success          = false
					, validationResult = translateValidationMessages( validationResult )
				});
			}

		} else {
			event.renderData( type="json", data={ success = false });
		}
	}

	private void function _checkObjectExists(
		  required any     event
		, required struct  rc
		, required struct  prc
		, required string  object
	) {
		if ( not presideObjectService.objectExists( object ) ) {
			messageBox.error( translateResource( uri="cms:datamanager.objectNotFound.error", data=[object] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.index" ) );
		}
	}

	private void function _checkNavigatePermission( event, rc, prc ) {
		if ( !hasCmsPermission( "datamanager.navigate" ) ) {
			event.adminAccessDenied();
		}
	}

	private any function _checkPermission(
		  required any     event
		, required struct  rc
		, required struct  prc
		, required string  key
		, required string  object
		,          boolean throwOnError    = true
		,          boolean checkOperations = true
	) {
		var operations = [ "read", "add", "edit", "delete", "viewversions" ];
		var permitted  = true;

		if ( arguments.checkOperations && operations.find( arguments.key ) && !datamanagerService.isOperationAllowed( arguments.object, arguments.key ) ) {
			permitted = false;
		} else if ( !hasCmsPermission( permissionKey="datamanager.#arguments.key#", context="datamanager", contextKeys=[ arguments.object ] ) && !hasCmsPermission( permissionKey="presideobject.#arguments.object#.#arguments.key#" ) ) {
			permitted = false;
		} else {
			var allowedSiteTemplates = presideObjectService.getObjectAttribute( objectName=arguments.object, attributeName="siteTemplates", defaultValue="*" );

			if ( allowedSiteTemplates != "*" && !ListFindNoCase( allowedSiteTemplates, siteService.getActiveSiteTemplate() ) ) {
				permitted = false;
			}
		}

		if ( !permitted && arguments.throwOnError ) {
			event.adminAccessDenied();
		}

		return permitted;
	}

	private any function _batchEditForm(
		  required any     event
		, required struct  rc
		, required struct  prc
		,          struct  args = {}
	) {
		var object      = args.object ?: "";
		var field       = args.field  ?: "";
		var ids         = args.ids    ?: "";
		var recordCount = ListLen( ids );
		var objectName  = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object ?: "" );
		var fieldName   = translateResource( uri="preside-objects.#object#:field.#field#.title", defaultValue=field );

		args.fieldFormControl = formsService.renderFormControlForObjectField(
		      objectName = object
		    , fieldName  = field
		);

		if ( presideObjectService.isManyToManyProperty( object, field ) ) {
			args.multiEditBehaviourControl = renderFormControl(
				  type   = "select"
				, name   = "multiValueBehaviour"
				, label  = translateResource( uri="cms:datamanager.multiValueBehaviour.title" )
				, values = [ "append", "overwrite", "delete" ]
				, labels = [ translateResource( uri="cms:datamanager.multiDataAppend.title" ), translateResource( uri="cms:datamanager.multiDataOverwrite.title" ), translateResource( uri="cms:datamanager.multiDataDeleteSelected.title" ) ]
			);

			args.batchEditWarning = args.batchEditWarning ?: translateResource(
				  uri  = "cms:datamanager.batch.edit.warning.multi.value"
				, data = [ "<strong>#objectName#</strong>", "<strong>#fieldName#</strong>", "<strong>#NumberFormat( recordCount )#</strong>" ]
			);
		} else {
			args.batchEditWarning = args.batchEditWarning ?: translateResource(
				  uri  = "cms:datamanager.batch.edit.warning"
				, data = [ "<strong>#objectName#</strong>", "<strong>#fieldName#</strong>", "<strong>#NumberFormat( recordCount )#</strong>" ]
			);
		}

		return renderView( view="/admin/datamanager/_batchEditForm", args=args );
	}

	private void function _exportDataAction(
		  required any    event
		, required struct rc
		, required struct prc
		,          string exporter          = ( rc.exporter          ?: 'CSV' )
		,          string objectName        = ( rc.object            ?: '' )
		,          string exportFields      = ( rc.exportFields      ?: '' )
		,          string filename          = ( rc.fileName          ?: '' )
		,          string filterExpressions = ( rc.filterExpressions ?: '' )
		,          string savedFilters      = ( rc.savedFilters      ?: '' )
		,          array  extraFilters      = []
		,          string returnUrl         = cgi.http_referer

	) {
		var exporterDetail = dataExportService.getExporterDetails( arguments.exporter );
		var selectFields   = arguments.exportFields.listToArray();
		var fullFileName   = arguments.fileName & ".#exporterDetail.fileExtension#";
		var args           = {
			  exporter       = exporter
			, objectName     = objectName
			, selectFields   = selectFields
			, extraFilters   = arguments.extraFilters
			, autoGroupBy    = true
			, exportFileName = fullFileName
			, mimetype       = exporterDetail.mimeType
		};

		try {
			args.extraFilters.append( rulesEngineFilterService.prepareFilter(
				  objectName      = objectName
				, expressionArray = DeSerializeJson( arguments.filterExpressions )
			) );
		} catch( any e ){}

		for( var filter in arguments.savedFilters.listToArray() ) {
			try {
				args.extraFilters.append( rulesEngineFilterService.prepareFilter(
					  objectName = objectName
					, filterId   = filter
				) );
			} catch( any e ){}
		}

		var taskId = createTask(
			  event             = "admin.datahelpers.exportDataInBackgroundThread"
			, args              = args
			, runNow            = true
			, adminOwner        = event.getAdminUserId()
			, discardOnComplete = false
			, title             = "cms:dataexport.task.title"
			, resultUrl         = event.buildAdminLink( linkto="datahelpers.downloadExport", querystring="taskId={taskId}" )
			, returnUrl         = arguments.returnUrl
		);

		setNextEvent( url=event.buildAdminLink(
			  linkTo      = "adhoctaskmanager.progress"
			, queryString = "taskId=" & taskId
		) );
	}

	private string function _oneToManyListingActions( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		args.canEdit   = datamanagerService.isOperationAllowed( objectName, "edit"   );
		args.canDelete = datamanagerService.isOperationAllowed( objectName, "delete" );

		return renderView( view="/admin/datamanager/_oneToManyListingActions", args=args );
	}

<!--- private utility methods --->
	private array function _getObjectFieldsForGrid( required string objectName ) {
		return dataManagerService.listGridFields( arguments.objectName );
	}

	private void function _addObjectNameBreadCrumb( required any event, required string objectName ) {
		event.addAdminBreadCrumb(
			  title = translateResource( "preside-objects.#objectName#:title" )
			, link  = event.buildAdminLink( linkTo="datamanager.object", querystring="id=#objectName#" )
		);
	}

	private void function _addViewRecordBreadCrumb( required any event, required string objectName, required string recordId ) {
		var recordLabel = "";
		try {
			recordLabel = prc.recordLabel ?: renderLabel( objectName, recordId );
		} catch ( "PresideObjectService.no.label.field" e ) {
			recordLabel = prc.recordLabel = recordId;
		}

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:datamanager.viewrecord.breadcrumb.title", data=[ recordLabel ] )
			, link  = event.buildAdminLink( linkTo="datamanager.viewRecord", querystring="object=#objectName#&id=#recordId#" )
		);
	}

	private boolean function _objectCanBeViewedInDataManager( required any event, required string objectName, boolean relocateIfNoAccess=false ) {
		if ( dataManagerService.isObjectAvailableInDataManager( arguments.objectName ) ) {
			return true;
		}

		if ( arguments.relocateIfNoAccess ) {
			messageBox.error( translateResource( uri="cms:datamanager.objectNotManagedByManager.error", data=[ objectName ] ) );
			setNextEvent(
				url = event.buildAdminLink( "datamanager" )
			);
		}
		return false;
	}

	private struct function _getParentDetailsForOneToManyActions( event, rc, prc ) {
		var object          = rc.object          ?: "";
		var parentId        = rc.parentId        ?: "";
		var relationshipKey = rc.relationshipKey ?: "";
		var parentObject    = presideObjectService.getObjectPropertyAttribute(
			  objectName    = object
			, propertyName  = relationshipKey
			, attributeName = "relatedTo"
		);
		var parentRecord      = presideObjectService.selectData( objectName=parentObject, id=parentId, selectFields=[ "${labelfield} as label" ] );
		var parentObjectTitle = "";

		if ( presideObjectService.isPageType( parentObject ) ) {
			parentObjectTitle = translateResource( "page-types.#parentObject#:name" );
		} else {
			parentObjectTitle = translateResource( "preside-objects.#parentObject#:title.singular" );
		}

		return {
			  parentObject      = parentObject
			, parentRecordLabel = parentRecord.label ?: ""
			, parentObjectTitle = parentObjectTitle
		};
	}
}