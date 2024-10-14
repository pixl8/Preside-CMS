/**
 * @feature formbuilder
 */
component extends="preside.system.base.AdminHandler" {

	property name="formBuilderService"          inject="formBuilderService";
	property name="formBuilderRenderingService" inject="formBuilderRenderingService";
	property name="itemTypesService"            inject="formBuilderItemTypesService";
	property name="actionsService"              inject="formBuilderActionsService";
	property name="messagebox"                  inject="messagebox@cbmessagebox";
	property name="adHocTaskManagerService"     inject="adHocTaskManagerService";
	property name="submissionRemovalMinDays"    inject="coldbox:setting:formbuilder.submissions.removal.minAllowedDays";

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
		prc.canEdit   = hasCmsPermission( permissionKey="formbuilder.editform" );
		prc.canDelete = hasCmsPermission( permissionKey="formbuilder.deleteform" );
	}

	public void function addForm( event, rc, prc ) {
		_permissionsCheck( "addform", event );

		prc.pageTitle      = translateResource( "formbuilder:add.form.page.title" );
		prc.pageSubtitle   = translateResource( "formbuilder:add.form.page.subtitle" );
		prc.additionalArgs = { fields={ submission_remove_after={ minValue=submissionRemovalMinDays } } };

		event.include( "/js/admin/specific/formbuilder/form/" );
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
		_permissionsCheck( "editform", event );

		var formId = rc.formId ?: "";
		var clone  = isTrue( rc.clone ?: "" );

		if ( Len( Trim( rc.itemId ?: "" ) ) ) {
			var item = formBuilderService.getFormItem( rc.itemId );

			item.configuration.name  = clone ? "" : ( item.configuration.name  ?: "" );
			item.configuration.label = clone ? "" : ( item.configuration.label ?: "" );
			if ( item.count() ) {
				prc.savedData = item.configuration;
				prc.savedData.question = item.questionId ?: "";
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

		if ( IsTrue( prc.itemTypeConfig.isFormField ?: "" ) && formBuilderService.isV2Form( formId ) ) {
			prc.formName = "formbuilder.item-types.formfieldv2";
			prc.additionalFormArgs = { fields={ question={
				placeholder = translateResource( uri="preside-objects.formbuilder_formitem:field.question.placeholder.custom", data=[ prc.itemTypeConfig.title ] )
			} } };
		} else {
			prc.formName = prc.itemTypeConfig.configFormName ?: "";
		}
	}

	public void function validateItemConfig( event, rc, prc ) {
		_permissionsCheck( "editform", event );

		var formId         = rc.formId   ?: "";
		var itemId         = rc.itemId   ?: "";
		var questionId     = rc.question ?: "";
		var formName       = "";
		var itemTypeConfig = itemTypesService.getItemTypeConfig( rc.itemType ?: "" );

		if ( isTrue( itemTypeConfig.isFormField ?: "" ) && formBuilderService.isV2Form( formId ) ) {
			formName = "formbuilder.item-types.formfieldv2";
		} else {
			formName = itemTypeConfig.configFormName ?: "";
		}

		var validationResult = validateForm( formName, event.getCollectionForForm( formName ) );

		if ( validationResult.validated() && formBuilderService.isV2Form( formId ) && itemTypeConfig.isFormField ) {
			var formItems = formBuilderService.getFormItems( formId );
			for ( var item in formItems ) {
				if ( itemId != item.id && questionId == (item.questionId ?: "") ) {
					validationResult.addError(
						  fieldName = "question"
						, message   = translateResource( uri="preside-objects.formbuilder_formitem:field.question.duplicate.error" )
					);
					break;
				}
			}
		}
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
			, link  = event.buildAdminLink( linkTo="formbuilder.actions", queryString="id=" & prc.form.id )
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
			, link  = event.buildAdminLink( linkTo="formbuilder.submissions", queryString="id=" & prc.form.id )
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

		prc.pageTitle      = translateResource( uri="formbuilder:edit.form.page.title"   , data=[ prc.form.name ] );
		prc.canEdit        = hasCmsPermission( permissionKey="formbuilder.editform" );
		prc.additionalArgs = { fields={ submission_remove_after={ minValue=submissionRemovalMinDays } } };

		event.include( "/js/admin/specific/formbuilder/form/" );
		event.addAdminBreadCrumb(
			  title = translateResource( uri="formbuilder:manageform.breadcrumb.title", data=[ prc.form.name ] )
			, link  = event.buildAdminLink( linkTo="formbuilder.manageform", queryString="id=" & prc.form.id )
		);
		event.addAdminBreadCrumb(
			  title = translateResource( uri="formbuilder:edit.form.breadcrumb.title", data=[ prc.form.name ] )
			, link  = event.buildAdminLink( linkTo="formbuilder.editform", queryString="id=" & prc.form.id )
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

	public void function exportQuestionResponsesConfig( event, rc, prc ) {
		if ( !isFeatureEnabled( "dataexport" ) ) {
			event.notFound();
		}
		var args   = {};

		args.objectName            = "formbuilder_question_response";
		args.objectTitle           = "";
		args.defaultExporter       = getSetting( name="dataExport.defaultExporter" , defaultValue="" );

		event.setView( view="/admin/datamanager/formbuilder_question/dataExportConfigModal", layout="adminModalDialog", args=args );
	}

	public void function exportQuestionResponses( event, rc, prc ) {
		var questionId         =  rc.questionId        ?: "";
		var exportFields       =  rc.exportFields      ?: "id,submission_type,submission_reference,submitted_by,datecreated,is_website_user,parent_name";
		var exporter           =  rc.exporter          ?: "Excel";

		var theQuestion        =      formBuilderService.getQuestion( questionId );

		if ( !theQuestion.recordCount ) {
			event.adminNotFound();
		}

		var taskId = createTask(
			  event             = "admin.formbuilder.exportQuestionResponsesInBackgroundThread"
			, args              = {
									  questionId        = questionId
									, exportFields      = exportFields
									, exporter          = exporter
									, filterExpressions = rc.filterExpressions ?: ""
									, savedFilters      = rc.savedFilters      ?: ""
								  }
			, runNow            = true
			, adminOwner        = event.getAdminUserId()
			, discardOnComplete = false
			, title             = "cms:formbuilder.export.task.title"
			, resultUrl         = event.buildAdminLink( linkto="formbuilder.downloadExport", querystring="taskId={taskId}" )
			, returnUrl         = event.buildAdminLink( linkto="datamanager.formbuilder.viewRecord", querystring="id=" & questionId )
		);

		setNextEvent( url=event.buildAdminLink(
			  linkTo      = "adhoctaskmanager.progress"
			, queryString = "taskId=" & taskId
		) );
	}

	private void function exportQuestionResponsesInBackgroundThread( event, rc, prc, args={}, logger, progress ) {
		var questionId   = args.questionId   ?: "";
		var exportFields = args.exportFields ?: "id,submission_type,submission_reference,submitted_by,datecreated,is_website_user,parent_name";
		var exporter     = args.exporter     ?: "Excel"

		formBuilderService.exportQuestionResponses(
			  questionId        = questionId
			, exportFields      = exportFields
			, exporter          = exporter
			, filterExpressions = args.filterExpressions
			, savedFilters      = args.savedFilters
			, writeToFile       = true
			, logger            = arguments.logger   ?: NullValue()
			, progress          = arguments.progress ?: NullValue()
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
				, audit            = true
				, auditAction      = "formbuilder_add_form"
				, auditType        = "formbuilder"
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
				, audit            = true
				, auditAction      = "formbuilder_edit_form"
				, auditType        = "formbuilder"
			}
		);
	}

	public void function addItemAction( event, rc, prc ) {
		_permissionsCheck( "editform", event );

		var configuration = event.getCollectionWithoutSystemVars();

		configuration.delete( "formId"   );
		configuration.delete( "itemType" );
		configuration.delete( "question" );
		configuration.delete( "_sid" );

		var newId = formBuilderService.addItem(
			  formId        = rc.formId   ?: ""
			, itemType      = rc.itemType ?: ""
			, configuration = configuration
			, question      = rc.question ?: ""
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
		configuration.delete( "question" );

		formBuilderService.saveItem(
			  id            = itemId
			, configuration = configuration
			, question      = rc.question ?: ""
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
		_permissionsCheck( "deleteSubmissions", event );

		var formId = rc.formId ?: "";

		if ( !Len( Trim( formId ) ) ) {
			event.adminNotFound();
		}

		var formForm = formBuilderService.getForm( id=formId );

		runEvent(
			  event          = "admin.DataManager._deleteRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object        = "formbuilder_formsubmission"
				, postActionUrl = event.buildAdminLink( linkTo="formbuilder.submissions", queryString="id=" & formId )
				, audit         = true
				, auditAction   = "formbuilder_delete_submission"
				, auditType     = "formbuilder"
				, auditDetail   = {
					  formId   = formForm.id   ?: ""
					, formName = formForm.name ?: ""
				}
			}
		);
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
		var sFilterExpression     = ( structKeyExists( rc, 'sFilterExpression' ) && Len( Trim( rc.sFilterExpression ) ) ) ? rc.sFilterExpression : "";

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
			, sFilterExpression     = sFilterExpression
			, savedFilterExpIdLists = savedFilterExpIdLists
		);
		var records = Duplicate( results.records );
		var viewSubmissionTitle   = translateResource( "formbuilder:view.submission.modal.title" );
		var deleteSubmissionTitle = translateResource( "formbuilder:delete.submission.prompt" );

		for( var record in records ){
			for( var field in gridFields ){
				records[ field ][ records.currentRow ] = renderField(
					  object   = "formbuilder_formsubmission"
					, property = field
					, data     = record[ field ]
					, context  = [ "adminDataTable", "admin" ]
					, editable = false
					, recordId = record.id
					, record   = record
				);
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
		prc.pageTitle = translateResource( "formbuilder:cloneForm.page.title" );

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

		var id      = rc.id ?: "";
		var isBatch = ListLen( id ) > 1;

		if ( isBatch ) {
			_deleteForm( argumentCollection=arguments, id=id, isBatch=true );
		} else {
			var taskId = createTask(
				  event             = "admin.FormBuilder.deleteFormInBgThread"
				, args              = {
					id = id
				  }
				, runNow            = true
				, adminOwner        = event.getAdminUserId()
				, discardOnComplete = false
				, title             = "formbuilder:task.form.delete.title"
				, returnUrl         = event.buildAdminLink( linkTo="formbuilder" )
			);

			setNextEvent( url=event.buildAdminLink(
				  linkTo      = "adhoctaskmanager.progress"
				, queryString = "taskId=#taskId#"
			) );
		}
	}

	public void function importFormFields( event, rc, prc, args ) {
		prc.pageTitle = translateResource( "formbuilder:importFormFields.page.title" );
		prc.pageIcon  = "file-import";

		event.addAdminBreadCrumb(
			  title = prc.pageTitle
			, link  = ""
		);
	}

	public string function importFormFieldsAction( event, rc, prc, args ) {
		var formId = rc.id ?: "";

		var formData         = event.getCollectionWithoutSystemVars()
		var validationResult = validateForms( formData );

		if ( !validationResult.validated() ) {
			messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );

			formData.validationResult = validationResult;

			setNextEvent( url=event.buildAdminLink( linkTo="formbuilder.importFormFields", queryString="id=#formId#" ), persistStruct=formData );
		}

		try {
			var data = DeserializeJSON( ToString( formData.formFieldsFile.binary ?: "{}" ) );

			var taskId = createTask(
				  event             = "admin.FormBuilder.importFormFieldsInBackgroundThread"
				, args              = { formId=formId, data=data }
				, runNow            = true
				, adminOwner        = event.getAdminUserId()
				, discardOnComplete = false
				, title             = "formbuilder:task.form.delete.title"
				, returnUrl         = event.buildAdminLink( linkto="formbuilder.manageForm", queryString="id=#formId#" )
			);

			setNextEvent( url=event.buildAdminLink(
				  linkTo      = "adhoctaskmanager.progress"
				, queryString = "taskId=" & taskId
			) );
		} catch ( any e ) {
			logError( e );

			messageBox.error( translateResource( uri="formbuilder:importFormFields.message.error" ) );

			setNextEvent( url=event.buildAdminLink( linkTo="formbuilder.importFormFields", queryString="id=#formId#" ), persistStruct=formData );
		}
	}

	private void function importFormFieldsInBackgroundThread( event, rc, prc, args={}, logger, progress ) {
		var canProgress = StructKeyExists( arguments, "progress" );

		logMessage( logger, "info", "Start importing the form fields..." );

		formBuilderService.importFormFields(
			  formId   = args.formId ?: ""
			, data     = args.data   ?: {}
			, logger   = logger
			, progress = progress
		);

		if ( canProgress ) {
			arguments.progress.setProgress( 100 );
		}

		logMessage( logger, "info", "Finished import." );
	}

	public string function exportFormFieldsAction( event, rc, prc, args ) {
		var filePath = formBuilderService.exportFormFields( formId=rc.id ?: "" );

		if ( isEmptyString( filePath ) ) {
			event.notFound();
		}

		var fileName = ListLast( filePath, "/" );

		header name="Content-Disposition" value="attachment; filename=""#fileName#""";
		content reset=true file=filePath deletefile=true type="application/json";
		abort;
	}

	private void function deleteFormInBgThread( event, rc, prc, args={}, logger, progress ) {
		logMessage( arguments.logger, "info", "Start deleting the form and all its data..." );

		_deleteForm( argumentCollection=arguments, id=args.id ?: "", isBatch=false );

		arguments.progress?.setProgress( 100 );

		logMessage( arguments.logger, "info", "Finished delete." );
	}

// VIEWLETS
	private string function removalAlert( event, rc, prc, args ) {
		if ( isTrue( args.submission_remove_enabled ?: "" ) ) {
			args.submissionRemovalNextRun = getPresideObject( "taskmanager_task" ).selectData(
				  filter       = { task_key="deleteExpiredFormBuilderSubmissions" }
				, selectFields = [ "next_run" ]
				, returntype   = "singleValue"
				, columnKey    = "next_run"
			);

			args.submissionToBeRemovedCount = getPresideObject( "formbuilder_formsubmission" ).selectData(
				  recordCountOnly = true
				, filter          = "form = :form and datecreated < :datecreated"
				, filterParams    = {
					  form        = args.id
					, datecreated = DateAdd( "d", -Val( args.submission_remove_after ), Now() )
				}
			);

			return renderView( view="/admin/formbuilder/_removalAlert", args=args );
		}

		return "";
	}

	private string function formDataTableGridFields( event, rc, prc, args ) {
		args.canEdit   = hasCmsPermission( permissionKey="formbuilder.editform" );
		args.canDelete = hasCmsPermission( permissionKey="formbuilder.deleteform" );

		return renderView( view="/admin/formbuilder/_formGridFields", args=args );
	}

	private string function questionResponseDataTableGridFields( event, rc, prc, args ) {
		return renderView( view="/admin/formbuilder/_questionResponseGridFields", args=args );
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
		args.canEdit     = hasCmsPermission( permissionKey="formbuilder.editform" );
		args.canDelete   = hasCmsPermission( permissionKey="formbuilder.deleteform" );

		return renderView( view="/admin/formbuilder/_statusControls", args=args );
	}

	private string function workbenchFormItem( event, rc, prc, args ) {
		args.placeholder = renderViewlet(
			  event = formBuilderRenderingService.getItemTypeViewlet( itemType=( args.type.id ?: "" ), context="adminPlaceholder" )
			, args  = args
		);
		args.isV2 = formbuilderService.isV2Form( args.formId ?: "" );

		if ( structIsEmpty( args.type ) ) {
			args.type = {
				  id                    = "notfound"
				, title                 = translateResource( uri="formbuilder.item-types.notfound:description", data=[ args.item_type ?: "" ] )
				, iconClass             = translateResource( uri="formbuilder.item-types.notfound:iconClass" )
				, requiresConfiguration = false
			};
		}

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

	private void function _deleteForm(
		  required string  id
		,          boolean isBatch = false
	) {
		runEvent(
			  event          = "admin.DataManager._deleteRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object            = "formbuilder_form"
				, postActionUrl     = event.buildAdminLink( linkTo="formbuilder" )
				, audit             = true
				, auditAction       = "formbuilder_delete_form"
				, auditType         = "formbuilder"
				, batch             = arguments.isBatch
				, redirectOnSuccess = arguments.isBatch
				, rc                = {
					    id          = arguments.id
					  , forceDelete = true
				  }
				, logger = arguments.logger ?: NullValue()
			}
		);
	}
}