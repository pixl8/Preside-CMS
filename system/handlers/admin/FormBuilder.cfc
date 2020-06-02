component extends="preside.system.base.AdminHandler" {

	property name="formBuilderService"          inject="formBuilderService";
	property name="formBuilderRenderingService" inject="formBuilderRenderingService";
	property name="itemTypesService"            inject="formBuilderItemTypesService";
	property name="actionsService"              inject="formBuilderActionsService";
	property name="messagebox"                  inject="messagebox@cbmessagebox";
	property name="adHocTaskManagerService"     inject="adHocTaskManagerService";


// PRE-HANDLER
	public void function preHandler( event, action, eventArguments ) {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "formbuilder" ) ) {
			event.notFound();
		}

		_permissionsCheck( "navigate", event );

		event.addAdminBreadCrumb(
			  title = translateResource( "formbuilder:breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="formbuilder" )
		);
		prc.pageIcon = "check-square-o";
	}

// DEFACTO PUBLIC ACTIONS
	public void function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( "formbuilder:page.title" );
		prc.pageSubtitle = translateResource( "formbuilder:page.subtitle" );

		prc.canAdd    = hasCmsPermission( permissionKey="formbuilder.addform" );
		prc.canDelete = hasCmsPermission( permissionKey="formbuilder.deleteform" );
	}

	public void function addForm( event, rc, prc ) {
		_permissionsCheck( "addform", event );

		prc.pageTitle    = translateResource( "formbuilder:add.form.page.title" );
		prc.pageSubtitle = translateResource( "formbuilder:add.form.page.subtitle" );

		event.addAdminBreadCrumb(
			  title = translateResource( "formbuilder:addform.breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="formbuilder.addform" )
		);
	}

	public void function manageForm( event, rc, prc ) {
		prc.form = formBuilderService.getForm( rc.id ?: "" );

		if ( !prc.form.recordcount ) {
			messagebox.error( translateResource( "formbuilder:form.not.found.alert" ) );
			setNextEvent( url=event.buildAdminLink( "formbuilder" ) );
		}

		if ( IsTrue( prc.form.locked ) || !hasCmsPermission( permissionKey="formbuilder.editform" ) ) {
			setNextEvent( url=event.buildAdminLink( linkTo="formbuilder.submissions", queryString="id=" & prc.form.id ) );
		}

		prc.pageTitle    = prc.form.name;
		prc.pageSubtitle = prc.form.description;

		event.addAdminBreadCrumb(
			  title = translateResource( uri="formbuilder:manageform.breadcrumb.title", data=[ prc.form.name ] )
			, link  = event.buildAdminLink( linkTo="formbuilder.manageform", queryString="id=" & prc.form.id )
		);

		event.include( "/js/admin/specific/formbuilder/workbench/" );
		event.include( "/css/admin/specific/formbuilder/workbench/" );
		event.includeData( {
			  "formbuilderFormId"               = prc.form.id
			, "formbuilderSaveNewItemEndpoint"  = event.buildAdminLink( linkTo="formbuilder.addItemAction" )
			, "formbuilderDeleteItemEndpoint"   = event.buildAdminLink( linkTo="formbuilder.deleteItemAction" )
			, "formbuilderSaveItemEndpoint"     = event.buildAdminLink( linkTo="formbuilder.saveItemAction" )
			, "formbuilderSetSortOrderEndpoint" = event.buildAdminLink( linkTo="formbuilder.setSortOrderAction" )
		} );
	}

	public void function itemConfigDialog( event, rc, prc ) {
		var clone = rc.clone ?: false;
		_permissionsCheck( "editform", event );

		if ( Len( Trim( rc.itemId ?: "" ) ) ) {
			var item = formBuilderService.getFormItem( rc.itemId );
			item.configuration.name  = isTrue( clone ) ? "" : ( item.configuration.name  ?: "" );
			item.configuration.label = isTrue( clone ) ? "" : ( item.configuration.label ?: "" );
			if ( item.count() ) {
				prc.savedData = item.configuration;
			}
		}

		prc.itemTypeConfig = itemTypesService.getItemTypeConfig( rc.itemType ?: "" );
		prc.pageTitle      = translateResource( uri="formbuilder:itemconfig.dialog.title"   , data=[ prc.itemTypeConfig.title ] );
		prc.pageSubTitle   = translateResource( uri="formbuilder:itemconfig.dialog.subtitle", data=[ prc.itemTypeConfig.title ] );
		prc.pageIcon       = "cog";

		if ( !prc.itemTypeConfig.count() ) {
			event.adminNotFound();
		}

		event.setLayout( "adminModalDialog" );

		event.include( "/js/admin/specific/formbuilder/configdialog/" );
		event.includeData( {
			"formBuilderValidationEndpoint" = event.buildAdminLink( linkTo="formbuilder.validateItemConfig" )
		} );
	}

	public void function validateItemConfig( event, rc, prc ) {
		_permissionsCheck( "editform", event );

		var config = event.getCollectionWithoutSystemVars();

		config.delete( "formId"   );
		config.delete( "itemId"   );
		config.delete( "itemType" );

		var validationResult = formBuilderService.validateItemConfig(
			  formId    = rc.formId   ?: ""
			, itemId    = rc.itemId   ?: ""
			, itemType  = rc.itemType ?: ""
			, config    = config
		);

		if ( validationResult.validated() ) {
			event.renderData( data=true, type="json" );
		} else {
			var errors = {};
			var messages = validationResult.getMessages();

			for( var fieldName in messages ){
				errors[ fieldName ] = translateResource( uri=messages[ fieldName ].message, defaultValue=messages[ fieldName ].message, data=messages[ fieldName ].params ?: [] );
			}
			event.renderData( data=errors, type="json" );
		}
	}

	public void function actions( event, rc, prc ) {
		_permissionsCheck( "editformactions", event );

		prc.form = formBuilderService.getForm( rc.id ?: "" );

		if ( !prc.form.recordcount ) {
			messagebox.error( translateResource( "formbuilder:form.not.found.alert" ) );
			setNextEvent( url=event.buildAdminLink( "formbuilder" ) );
		}

		prc.pageTitle    = prc.form.name;
		prc.pageSubtitle = prc.form.description;

		event.addAdminBreadCrumb(
			  title = translateResource( uri="formbuilder:manageform.breadcrumb.title", data=[ prc.form.name ] )
			, link  = event.buildAdminLink( linkTo="formbuilder.manageform", queryString="id=" & prc.form.id )
		);
		event.addAdminBreadCrumb(
			  title = translateResource( uri="formbuilder:actions.breadcrumb.title", data=[ prc.form.name ] )
			, link  = event.buildAdminLink( linkTo="formbuilder.actions", queryStrign="id=" & prc.form.id )
		);


		event.include( "/js/admin/specific/formbuilder/workbench/" );
		event.include( "/css/admin/specific/formbuilder/workbench/" );
		event.includeData( {
			  "formbuilderFormId"               = prc.form.id
			, "formbuilderSaveNewItemEndpoint"  = event.buildAdminLink( linkTo="formbuilder.addActionAction" )
			, "formbuilderDeleteItemEndpoint"   = event.buildAdminLink( linkTo="formbuilder.deleteActionAction" )
			, "formbuilderSaveItemEndpoint"     = event.buildAdminLink( linkTo="formbuilder.saveActionAction" )
			, "formbuilderSetSortOrderEndpoint" = event.buildAdminLink( linkTo="formbuilder.setActionsSortOrderAction" )
		} );

	}

	public void function actionConfigDialog( event, rc, prc ) {
		_permissionsCheck( "editformactions", event );

		if ( Len( Trim( rc.actionId ?: "" ) ) ) {
			var action = actionsService.getFormAction( rc.actionId );
			if ( action.count() ) {
				prc.savedData = action.configuration;
				prc.savedData.condition = action.condition;
				rc.formId = action.formId;
			}
		}

		prc.actionConfig = actionsService.getActionConfig( rc.action ?: "" );

		if ( !prc.actionConfig.count() ) {
			event.adminFound();
		}

		prc.pageTitle    = translateResource( uri="formbuilder:action.config.dialog.title"   , data=[ prc.actionConfig.title ] );
		prc.pageSubTitle = translateResource( uri="formbuilder:action.config.dialog.subtitle", data=[ prc.actionConfig.title ] );
		prc.pageIcon     = "cog";

		event.setLayout( "adminModalDialog" );

		event.include( "/js/admin/specific/formbuilder/configdialog/" );
		event.includeData( {
			"formBuilderValidationEndpoint" = event.buildAdminLink( linkTo="formbuilder.validateActionConfig" )
		} );
	}

	public void function validateActionConfig( event, rc, prc ) {
		_permissionsCheck( "editformactions", event );

		var config = event.getCollectionWithoutSystemVars();

		config.delete( "formId"   );
		config.delete( "actionId" );
		config.delete( "action"   );

		var validationResult = actionsService.validateActionConfig(
			  formId   = rc.formId   ?: ""
			, actionId = rc.actionId ?: ""
			, action   = rc.action   ?: ""
			, config   = config
		);

		if ( validationResult.validated() ) {
			event.renderData( data=true, type="json" );
		} else {
			var errors = {};
			var messages = validationResult.getMessages();

			for( var fieldName in messages ){
				errors[ fieldName ] = translateResource( uri=messages[ fieldName ].message, defaultValue=messages[ fieldName ].message, data=messages[ fieldName ].params ?: [] );
			}
			event.renderData( data=errors, type="json" );
		}
	}

	public void function submissions( event, rc, prc ) {
		prc.form = formBuilderService.getForm( rc.id ?: "" );

		if ( !prc.form.recordcount ) {
			messagebox.error( translateResource( "formbuilder:form.not.found.alert" ) );
			setNextEvent( url=event.buildAdminLink( "formbuilder" ) );
		}

		prc.pageTitle    = prc.form.name;
		prc.pageSubtitle = prc.form.description;

		event.addAdminBreadCrumb(
			  title = translateResource( uri="formbuilder:manageform.breadcrumb.title", data=[ prc.form.name ] )
			, link  = event.buildAdminLink( linkTo="formbuilder.manageform", queryString="id=" & prc.form.id )
		);
		event.addAdminBreadCrumb(
			  title = translateResource( uri="formbuilder:submissions.breadcrumb.title", data=[ prc.form.name ] )
			, link  = event.buildAdminLink( linkTo="formbuilder.submissions", queryStrign="id=" & prc.form.id )
		);

	}

	public void function editForm( event, rc, prc ) {
		_permissionsCheck( "editform", event );

		prc.form = formBuilderService.getForm( rc.id ?: "" );

		if ( !prc.form.recordcount ) {
			messagebox.error( translateResource( "formbuilder:form.not.found.alert" ) );
			setNextEvent( url=event.buildAdminLink( "formbuilder" ) );
		}
		if ( IsTrue( prc.form.locked ) ) {
			setNextEvent( url=event.buildAdminLink( linkTo="formbuilder.submissions", queryString="id=" & prc.form.id ) );
		}

		prc.form = QueryRowToStruct( prc.form );

		prc.pageTitle    = translateResource( uri="formbuilder:edit.form.page.title"   , data=[ prc.form.name ] );
		prc.canEdit      = hasCmsPermission( permissionKey="formbuilder.editform" );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="formbuilder:manageform.breadcrumb.title", data=[ prc.form.name ] )
			, link  = event.buildAdminLink( linkTo="formbuilder.manageform", queryString="id=" & prc.form.id )
		);
		event.addAdminBreadCrumb(
			  title = translateResource( uri="formbuilder:edit.form.breadcrumb.title", data=[ prc.form.name ] )
			, link  = event.buildAdminLink( linkTo="formbuilder.editform", queryStrign="id=" & prc.form.id )
		);
	}

	public void function viewSubmission( event, rc, prc ) {
		prc.submission = formBuilderService.getSubmission( rc.id ?: "" );

		if ( !prc.submission.recordCount ) {
			event.adminNotFound();
		}

		rc.formId = prc.submission.form;

		event.noLayout();
	}

	public void function exportSubmissions( event, rc, prc ) {
		var formId   = rc.formId ?: "";
		var theForm  = formBuilderService.getForm( formId );

		if ( !theForm.recordCount ) {
			event.adminNotFound();
		}

		var taskId = createTask(
			  event             = "admin.formbuilder.exportSubmissionsInBackgroundThread"
			, args              = { formId=formId }
			, runNow            = true
			, adminOwner        = event.getAdminUserId()
			, discardOnComplete = false
			, title             = "cms:formbuilder.export.task.title"
			, resultUrl         = event.buildAdminLink( linkto="formbuilder.downloadExport", querystring="taskId={taskId}" )
			, returnUrl         = event.buildAdminLink( linkto="formbuilder.manageForm", querystring="id=" & formId )
		);

		setNextEvent( url=event.buildAdminLink(
			  linkTo      = "adhoctaskmanager.progress"
			, queryString = "taskId=" & taskId
		) );
	}

	private void function exportSubmissionsInBackgroundThread( event, rc, prc, args={}, logger, progress ) {
		var formId = args.formId ?: "";

		formBuilderService.exportResponsesToExcel(
			  formId      = formId
			, writeToFile = true
			, logger      = arguments.logger   ?: NullValue()
			, progress    = arguments.progress ?: NullValue()
		);
	}

	public void function downloadExport( event, rc, prc ) {
		var taskId          = rc.taskId ?: "";
		var task            = adhocTaskManagerService.getProgress( taskId );
		var localExportFile = task.result.filePath       ?: "";
		var exportFileName  = task.result.exportFileName ?: "";
		var mimetype        = task.result.mimetype       ?: "";

		if ( task.isEmpty() || !localExportFile.len() || !FileExists( localExportFile ) ) {
			event.notFound();
		}

		createTask(
			  event             = "admin.formBuilder.discardExport"
			, args              = { taskId=taskId }
			, runIn             = CreateTimeSpan( 0, 0, 10, 0 )
			, discardOnComplete = true
		);

		header name="Content-Disposition" value="attachment; filename=""#exportFileName#""";
		content reset=true file=localExportFile deletefile=false type=mimetype;

		abort;

	}

	private void function discardExport( event, rc, prc, args={} ) {
		var taskId          = args.taskId ?: "";
		var task            = adhocTaskManagerService.getProgress( taskId );
		var localExportFile = task.result.filePath       ?: "";

		if ( !task.isEmpty() ) {
			adhocTaskManagerService.discardTask( taskId );

			if ( FileExists( localExportFile ) ) {
				FileDelete( localExportFile );
			}
		}
	}

// DOING STUFF ACTIONS
	public void function addFormAction( event, rc, prc ) {
		_permissionsCheck( "addform", event );

		runEvent(
			  event          = "admin.DataManager._addRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object           = "formbuilder_form"
				, errorAction      = "formbuilder.addform"
				, successAction    = "formbuilder.manageform"
				, addAnotherAction = "formbuilder.addform"
				, viewRecordAction = "formbuilder.manageform"
			}
		);
	}

	public void function editFormAction( event, rc, prc ) {
		_permissionsCheck( "editform", event );
		var formId = rc.id ?: "";
		if ( formBuilderService.isFormLocked( formId ) ) {
			event.adminAccessDenied();
		}

		runEvent(
			  event          = "admin.DataManager._editRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object           = "formbuilder_form"
				, errorUrl         = event.buildAdminLink( linkTo="formbuilder.editform", queryString="id=" & formId )
				, successUrl       = event.buildAdminLink( linkTo="formbuilder.manageform", queryString="id=" & formId )
			}
		);
	}

	public void function addItemAction( event, rc, prc ) {
		_permissionsCheck( "editform", event );

		var configuration = event.getCollectionWithoutSystemVars();

		configuration.delete( "formId"   );
		configuration.delete( "itemType" );

		var newId = formBuilderService.addItem(
			  formId        = rc.formId   ?: ""
			, itemType      = rc.itemType ?: ""
			, configuration = configuration
		);

		event.renderData( type="json", data={
			  id       = newId
			, itemView = renderViewlet( event="admin.formbuilder.workbenchFormItem", args=formBuilderService.getFormItem( newId ) )
		} );
	}

	public void function saveItemAction( event, rc, prc ) {
		_permissionsCheck( "editform", event );

		var configuration = event.getCollectionWithoutSystemVars();
		var itemId        = rc.id ?: "";

		configuration.delete( "id" );

		formBuilderService.saveItem(
			  id            = itemId
			, configuration = configuration
		);

		event.renderData( type="json", data={
			  id       = itemId
			, itemView = renderViewlet( event="admin.formbuilder.workbenchFormItem", args=formBuilderService.getFormItem( itemId ) )
		} );
	}

	public void function deleteItemAction( event, rc, prc ) {
		_permissionsCheck( "editform", event );

		var deleteSuccess = formBuilderService.deleteItem( rc.id ?: "" );

		event.renderData( data=deleteSuccess, type="json" );
	}

	public void function setSortOrderAction( event, rc, prc ) {
		_permissionsCheck( "editform", event );

		var itemsUpdated = formBuilderService.setItemsSortOrder( ListToArray( rc.itemIds ?: "" ) );
		var success      = itemsUpdated > 0;

		event.renderData( data=success, type="json" );
	}

	public void function activateAction( event, rc, prc ) {
		_permissionsCheck( "activateForm", event );

		var formId    = rc.id ?: "";
		var activated = IsTrue( rc.activated ?: "" );

		if ( formBuilderService.isFormLocked( formId ) ) {
			event.adminAccessDenied();
		}

		if ( activated ) {
			formBuilderService.activateForm( formId );
			messagebox.info( translateResource( "formbuilder:activated.confirmation" ) );
		} else {
			formBuilderService.deactivateForm( formId );
			messagebox.info( translateResource( "formbuilder:deactivated.confirmation" ) );
		}

		setNextEvent( url=event.buildAdminLink( linkTo="formbuilder.manageform", querystring="id=" & formId ) );
	}

	public void function lockAction( event, rc, prc ) {
		_permissionsCheck( "lockForm", event );

		var formId = rc.id ?: "";
		var locked = IsTrue( rc.locked ?: "" );

		if ( locked ) {
			formBuilderService.lockForm( formId );
			messagebox.info( translateResource( "formbuilder:locked.confirmation" ) );
		} else {
			formBuilderService.unlockForm( formId );
			messagebox.info( translateResource( "formbuilder:unlocked.confirmation" ) );
		}

		setNextEvent( url=event.buildAdminLink( linkTo="formbuilder.manageform", querystring="id=" & formId ) );

	}

	public void function deleteSubmissionsAction( event, rc, prc ) {
		var formId        = rc.formId ?: "";
		var submissionIds = ListToArray( rc.id ?: "" );

		_permissionsCheck( "deleteSubmissions", event );

		if ( !Len( Trim( formId ) ) ) {
			event.adminNotFound();
		}

		formBuilderService.deleteSubmissions( submissionIds );

		if ( submissionIds.len() == 1 ) {
			messagebox.info( translateResource( uri="formbuilder:submission.deleted.confirmation" ) );
		} else {
			messagebox.info( translateResource( uri="formbuilder:submissions.deleted.confirmation" ) );
		}

		setNextEvent( url=event.buildAdminLink( linkTo="formbuilder.submissions", queryString="id=" & formId ) );
	}


	public void function addActionAction( event, rc, prc ) {
		_permissionsCheck( "editformactions", event );

		var configuration = event.getCollectionWithoutSystemVars();

		configuration.delete( "formId" );
		configuration.delete( "action" );

		var newId = actionsService.addAction(
			  formId        = rc.formId ?: ""
			, action        = rc.action ?: ""
			, configuration = configuration
		);

		event.renderData( type="json", data={
			  id       = newId
			, itemView = renderViewlet( event="admin.formbuilder.workbenchFormAction", args=actionsService.getFormAction( newId ) )
		} );
	}

	public void function saveActionAction( event, rc, prc ) {
		_permissionsCheck( "editformactions", event );

		var configuration = event.getCollectionWithoutSystemVars();
		var actionId      = rc.id ?: "";

		configuration.delete( "id" );

		actionsService.saveAction(
			  id            = actionId
			, configuration = configuration
		);

		event.renderData( type="json", data={
			  id       = actionId
			, itemView = renderViewlet( event="admin.formbuilder.workbenchFormAction", args=actionsService.getFormAction( actionId ) )
		} );
	}

	public void function deleteActionAction( event, rc, prc ) {
		_permissionsCheck( "editformactions", event );

		var deleteSuccess = actionsService.deleteAction( rc.id ?: "" );

		event.renderData( data=deleteSuccess, type="json" );
	}

	public void function setActionsSortOrderAction( event, rc, prc ) {
		_permissionsCheck( "editformactions", event );

		var itemsUpdated = actionsService.setActionsSortOrder( ListToArray( rc.itemIds ?: "" ) );
		var success      = itemsUpdated > 0;

		event.renderData( data=success, type="json" );
	}


// AJAXY ACTIONS
	public void function getFormsForAjaxDataTables( event, rc, prc ) {
		prc.canDelete = hasCmsPermission( permissionKey="formbuilder.deleteform" );
		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object          = "formbuilder_form"
				, useMultiActions = prc.canDelete
				, gridFields      = "name,description,locked,active,active_from,active_to"
				, actionsView     = "admin.formbuilder.formDataTableGridFields"
			}
		);
	}

	public void function listSubmissionsForAjaxDataTable( event, rc, prc ) {
		var formId                = ( rc.formId ?: "" );
		var savedFilterExpIdLists = ( structKeyExists( rc, 'sSavedFilterExpressions' ) && Len( Trim( rc.sSavedFilterExpressions ) ) ) ? rc.sSavedFilterExpressions : "";

		if ( !Len( Trim( formId ) ) ) {
			event.adminNotFound();
		}
		var canDelete       = hasCmsPermission( "formbuilder.deleteSubmissions" );
		var useMultiActions = canDelete;
		var checkboxCol     = [];
		var optionsCol      = [];
		var gridFields      = [ "submitted_by", "datecreated", "form_instance", "submitted_data" ];
		var dtHelper        = getModel( "JQueryDatatablesHelpers" );
		var results         = formbuilderService.getSubmissionsForGridListing(
			  formId                = formId
			, startRow              = dtHelper.getStartRow()
			, maxRows               = dtHelper.getMaxRows()
			, orderBy               = dtHelper.getSortOrder()
			, searchQuery           = dtHelper.getSearchQuery()
			, savedFilterExpIdLists = savedFilterExpIdLists
		);
		var records = Duplicate( results.records );
		var viewSubmissionTitle   = translateResource( "formbuilder:view.submission.modal.title" );
		var deleteSubmissionTitle = translateResource( "formbuilder:delete.submission.prompt" );

		for( var record in records ){
			for( var field in gridFields ){
				records[ field ][ records.currentRow ] = renderField( "formbuilder_formsubmission", field, record[ field ], [ "adminDataTable", "admin" ] );
			}

			if ( useMultiActions ) {
				checkboxCol.append( renderView( view="/admin/datamanager/_listingCheckbox", args={ recordId=record.id } ) );
			}

			optionsCol.append( renderView( view="/admin/formbuilder/_submissionActions", args={
				  canDelete             = canDelete
				, viewSubmissionLink    = event.buildAdminLink( linkto="formbuilder.viewSubmission"         , queryString="id=#record.id#" )
				, deleteSubmissionLink  = event.buildAdminLink( linkto="formbuilder.deleteSubmissionsAction", queryString="id=#record.id#&formId=#formId#" )
				, viewSubmissionTitle   = viewSubmissionTitle
				, deleteSubmissionTitle = deleteSubmissionTitle
 			} ) );
		}

		if ( useMultiActions ) {
			QueryAddColumn( records, "_checkbox", checkboxCol );
			ArrayPrepend( gridFields, "_checkbox" );
		}

		QueryAddColumn( records, "_options" , optionsCol );
		ArrayAppend( gridFields, "_options" );

		event.renderData(
			  type = "json"
			, data = dtHelper.queryToResult( records, gridFields, results.totalRecords )
		);
	}

	public void function cloneForm( event, rc, prc, args ) {
		prc.pageTitle    = translateResource( "formbuilder:cloneForm.page.title" );

		event.addAdminBreadCrumb(
			  title = translateResource( "formbuilder:cloneForm.page.title" )
			, link  = ''
		);
	}

	public void function cloneFormAction( event, rc, prc ) {
		_permissionsCheck( "addform", event );

		var basedOnFormId    = rc.basedOnFormId ?: "";
		var formData         = event.getCollectionForForm( "preside-objects.formbuilder_form.admin.cloneForm" );
		var validationResult = validateForm( formName="preside-objects.formbuilder_form.admin.cloneForm", formData=formData );
		var persist          = "";

		if ( !validationResult.validated() ) {
			messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
			persist                  = formData;
			persist.validationResult = validationResult;
			setNextEvent( url=event.buildAdminLink( linkTo="formbuilder.cloneForm", queryString="id=#basedOnFormId#" ), persistStruct=persist );
		} else {
			// Here cloning a form with items and actions from original form, except submission data
			var newFormId    = formBuilderService.cloneForm( argumentCollection = rc );
			messagebox.info( translateResource( "formbuilder:cloned.success.message" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="formbuilder.manageform", queryString="id=#newFormId#" ) );
		}
	}

	public void function multiRecordAction( event, rc, prc ) {
		var action     = rc.multiAction ?: "";
		var listingUrl = event.buildAdminLink( linkto="formbuilder" );

		if ( not Len( Trim( rc.id ?: "" ) ) ) {
			messageBox.error( translateResource( "cms:datamanager.norecordsselected.error" ) );
			setNextEvent( url=listingUrl );
		}

		switch( action ){
			case "delete":
				return deleteRecordAction( argumentCollection = arguments );
			break;
		}

		messageBox.error( translateResource( "cms:datamanager.invalid.multirecord.action.error" ) );
		setNextEvent( url=listingUrl );
	}

	public void function deleteRecordAction( event, rc, prc ) {
		_permissionsCheck( "deleteform", event );

		var ids           = rc.id ?: "";
		var postActionUrl = event.buildAdminLink( linkto="formbuilder" );
		var messages      = "";

		if ( listLen(ids) == 1 ) {
			messages = translateResource( uri="cms:datamanager.recordDeleted.confirmation", data=[ "Form", renderLabel( "formbuilder_form", ids ) ] ) ;
		} else {
			messages = translateResource( uri="cms:datamanager.recordsDeleted.confirmation", data=[ "Forms", listLen(ids) ] );
		}

		formBuilderService.deleteForms( ids );

		messageBox.info( messages );

		setNextEvent( url=postActionUrl );
	}


// VIEWLETS
	private string function formDataTableGridFields( event, rc, prc, args ) {
		args.canEdit   = hasCmsPermission( permissionKey="formbuilder.editform" );
		args.canDelete = hasCmsPermission( permissionKey="formbuilder.deleteform" );

		return renderView( view="/admin/formbuilder/_formGridFields", args=args );
	}

	private string function itemTypePicker( event, rc, prc, args ) {
		args.itemTypesByCategory = itemTypesService.getItemTypesByCategory();

		return renderView( view="/admin/formbuilder/_itemTypePicker", args=args );
	}

	private string function itemsManagement( event, rc, prc, args ) {
		args.items = formBuilderService.getFormItems( args.formId ?: "" );
		return renderView( view="/admin/formbuilder/_itemsManagement", args=args );
	}

	private string function managementTabs( event, rc, prc, args ) {
		var formId   = rc.id ?: "";
		var isLocked = formBuilderService.isFormLocked( formId );

		args.canEdit         = !isLocked && hasCmsPermission( permissionKey="formbuilder.editform" );
		args.canEditActions  = !isLocked && hasCmsPermission( permissionKey="formbuilder.editformactions" );
		args.submissionCount = formBuilderService.getSubmissionCount( formId );
		args.actionCount     = actionsService.getActionCount( formId );

		return renderView( view="/admin/formbuilder/_managementTabs", args=args );
	}

	private string function statusControls( event, rc, prc, args ) {
		args.locked      = IsTrue( args.locked ?: "" );
		args.canLock     = hasCmsPermission( permissionKey="formbuilder.lockForm" );
		args.canActivate = !args.locked && hasCmsPermission( permissionKey="formbuilder.activateForm" );

		return renderView( view="/admin/formbuilder/_statusControls", args=args );
	}

	private string function workbenchFormItem( event, rc, prc, args ) {
		args.placeholder = renderViewlet(
			  event = formBuilderRenderingService.getItemTypeViewlet( itemType=( args.type.id ?: "" ), context="adminPlaceholder" )
			, args  = args
		);
		return renderView( view="/admin/formbuilder/_workbenchFormItem", args=args );
	}

	private string function actionsPicker( event, rc, prc, args ) {
		args.actions = actionsService.listActions();

		return renderView( view="/admin/formbuilder/_actionsPicker", args=args );
	}

	private string function actionsManagement( event, rc, prc, args ) {
		args.actions = actionsService.getFormActions( args.formId ?: "" );
		return renderView( view="/admin/formbuilder/_actionsManagement", args=args );
	}

	private string function workbenchFormAction( event, rc, prc, args ) {
		args.placeholder = renderViewlet(
			  event = formBuilderRenderingService.getActionViewlet( action=( args.action.id ?: "" ), context="adminPlaceholder" )
			, args  = args
		);
		return renderView( view="/admin/formbuilder/_workbenchFormAction", args=args );
	}



// PRIVATE UTILITY
	private void function _permissionsCheck( required string key, required any event ) {
		var permKey   = "formbuilder." & arguments.key;
		var permitted = hasCmsPermission( permissionKey=permKey );

		if ( !permitted ) {
			event.adminAccessDenied();
		}
	}
}