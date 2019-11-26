component extends="preside.system.base.AdminHandler" {

	property name="emailTemplateService"       inject="emailTemplateService";
	property name="systemEmailTemplateService" inject="systemEmailTemplateService";
	property name="emailRecipientTypeService"  inject="emailRecipientTypeService";
	property name="emailLayoutService"         inject="emailLayoutService";
	property name="emailMassSendingService"    inject="emailMassSendingService";
	property name="customizationService"       inject="dataManagerCustomizationService";
	property name="dataManagerService"         inject="dataManagerService";
	property name="presideObjectService"       inject="presideObjectService";
	property name="emailService"               inject="emailService";
	property name="formsService"               inject="formsService";
	property name="cloningService"             inject="presideObjectCloningService";
	property name="dao"                        inject="presidecms:object:email_template";
	property name="messageBox"                 inject="messagebox@cbmessagebox";

	function prehandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "emailcenter" ) || !isFeatureEnabled( "customEmailTemplates" ) ) {
			event.notFound();
		}


		_checkPermissions( event=event, key="navigate" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:emailcenter.customTemplates.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="emailCenter.customTemplates" )
		);

		prc.pageIcon = "envelope";
	}

	function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( "cms:emailcenter.customTemplates.page.title" );
		prc.pageSubtitle = translateResource( "cms:emailcenter.customTemplates.page.subtitle" );

		prc.canAdd    = hasCmsPermission( "emailCenter.customTemplates.add"    );
		prc.canDelete = hasCmsPermission( "emailCenter.customTemplates.delete" );
	}

	function add( event, rc, prc ) {
		_checkPermissions( event=event, key="add" );

		prc.pageTitle    = translateResource( "cms:emailcenter.customTemplates.add.page.title" );
		prc.pageSubtitle = translateResource( "cms:emailcenter.customTemplates.add.page.subtitle" );

		prc.canPublish   = hasCmsPermission( "emailCenter.customTemplates.publish" );
		prc.canSaveDraft = hasCmsPermission( "emailCenter.customTemplates.saveDraft"   );

		if ( !prc.canPublish && !prc.canSaveDraft ) {
			event.adminAccessDenied();
		}

		prc.additionalFormArgs = _getAdditionalAddEditFormArgs( argumentCollection=arguments );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:emailcenter.customTemplates.add.page.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="emailCenter.customTemplates.add" )
		);
	}
	function addAction( event, rc, prc ) {
		_checkPermissions( event=event, key="add" );

		var saveAction = ( rc._saveAction ?: "savedraft" ) == "publish" ? "publish" : "savedraft";
		_checkPermissions( event=event, key=saveAction );

		var formData         = event.getCollectionWithoutSystemVars()
		var validationResult = validateForms( formData );

		if ( validationResult.validated() ) {
			var id=emailTemplateService.saveTemplate( template=formData, isDraft=( saveAction=="savedraft" ) );

			messagebox.info( translateResource( "cms:emailcenter.customTemplates.template.added.confirmation" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="emailcenter.customTemplates.edit", queryString="id=#id#" ) );
		}

		formData.validationResult = validationResult;
		messagebox.error( translateResource( "cms:datamanager.data.validation.error" ) );
		setNextEvent(
			  url           = event.buildAdminLink( linkTo="emailcenter.customTemplates.add" )
			, persistStruct = formData
		);
	}

	function preview( event, rc, prc ) {
		_getTemplate( argumentCollection=arguments, allowDrafts=true )

		var id               = rc.id ?: "";
		var version          = Val( rc.version ?: "" );
		var previewRecipient = rc.previewRecipient ?: "";

		prc.pageTitle    = translateResource( uri="cms:emailcenter.customTemplates.preview.page.title", data=[ prc.record.name ] );
		prc.pageSubtitle = translateResource( uri="cms:emailcenter.customTemplates.preview.page.subtitle", data=[ prc.record.name ] );
		prc.preview      = emailTemplateService.previewTemplate(
			  template         = id
			, allowDrafts      = true
			, version          = version
			, previewRecipient = previewRecipient
		);

		prc.filterObject = emailRecipientTypeService.getFilterObjectForRecipientType( prc.template.recipient_type );
		prc.canPreviewWithRecipient = Len( Trim( prc.filterObject ) );
		if ( prc.canPreviewWithRecipient && Len( Trim( previewRecipient ) ) ){
			prc.previewRecipientName = renderLabel( prc.filterObject, previewRecipient );
		}

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.customTemplates.preview.page.breadcrumb", data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="emailCenter.customTemplates.preview", queryString="id=#id#" )
		);
	}

	function previewRecipientPicker( event, rc, prc ) {
		_getTemplate( argumentCollection=arguments, allowDrafts=true );

		prc.filterObject = emailRecipientTypeService.getFilterObjectForRecipientType( prc.template.recipient_type );
		prc.gridFields   = emailRecipientTypeService.getGridFieldsForRecipientType( prc.template.recipient_type );

		event.setLayout( "adminModalDialog" );
	}

	function sendTestModalForm( event, rc, prc ) {
		_getTemplate( argumentCollection=arguments, allowDrafts=true );

		prc.savedData = {
			  send_to   = event.getAdminUserDetails().email_address
			, recipient = rc.previewRecipient ?: ""
		};

		prc.formAction = event.buildAdminLink( linkto="emailcenter.customtemplates.sendTestAction", queryString="id=" & rc.id );
		prc.formName = _getTestSendFormName( argumentCollection=arguments );


		event.setLayout( "adminModalDialog" );
	}

	public void function sendTestAction( event, rc, prc ) {
		_getTemplate( argumentCollection=arguments, allowDrafts=true );

		var formName         = _getTestSendFormName( argumentCollection=arguments );
		var formData         = event.getCollectionForForm( formName );
		var validationResult = validateForm( formName, formData );
		var templateId       = rc.id ?: "";

		if ( validationResult.validated() ) {
			var sendTo    = ListToArray( formData.send_to ?: "", ",;#Chr(10)##Chr(13)#" );
			var recipient = formData.recipient ?: "";

			emailService.send(
				  template    = templateId
				, recipientId = recipient
				, to          = sendTo
				, isTest      = true
			);

			messageBox.info( translateResource( uri="cms:emailcenter.customTemplates.send.test.success", data=[ rc.send_to ] ) );
		} else {
			messageBox.error( translateResource( uri="cms:emailcenter.customTemplates.send.test.validation.failure" ) );
		}

		setNextEvent( url=event.buildAdminLink( linkTo="emailCenter.customTemplates.preview", queryString="id=#templateId#&previewRecipient=#rc.recipient#" ) );
	}

	public void function cancelSendAction( event, rc, prc ) {
		_getTemplate( argumentCollection=arguments, allowDrafts=true );
		_checkPermissions( event, "cancelsend" );

		var templateId = rc.id ?: "";

		emailTemplateService.clearQueue( templateId );
		messagebox.info( translateResource( uri="cms:emailcenter.queue.cleared", data=[ prc.record.name ] ) );

		setNextEvent( url=event.buildAdminLink( linkTo="emailCenter.customTemplates.preview", queryString="id=#templateId#" ) );
	}


	function edit( event, rc, prc ) {
		_checkPermissions( event=event, key="edit" );
		_getTemplate( argumentCollection=arguments, allowDrafts=true );

		prc.canSaveDraft = hasCmsPermission( "emailCenter.customTemplates.saveDraft" );
		prc.canPublish   = hasCmsPermission( "emailCenter.customTemplates.publish"   );
		if ( !prc.canSaveDraft && !prc.canPublish ) {
			event.adminAccessDenied()
		}

		var id = rc.id ?: "";

		prc.pageTitle    = translateResource( uri="cms:emailcenter.customTemplates.edit.page.title", data=[ prc.record.name ] );
		prc.pageSubtitle = translateResource( uri="cms:emailcenter.customTemplates.edit.page.subtitle", data=[ prc.record.name ] );
		prc.additionalFormArgs = _getAdditionalAddEditFormArgs( argumentCollection=arguments );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.customTemplates.edit.page.breadcrumb", data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="emailCenter.customTemplates.edit", queryString="id=#id#" )
		);
	}
	function editAction( event, rc, prc ) {
		_checkPermissions( event=event, key="edit" );
		_getTemplate( argumentCollection=arguments, allowDrafts=true );

		var id = rc.id ?: "";
		var saveAction = ( rc._saveAction ?: "savedraft" ) == "publish" ? "publish" : "savedraft";
		_checkPermissions( event=event, key=saveAction );


		var formName         = "preside-objects.email_template.admin.edit";
		var formData         = event.getCollectionForForm( formName );
		    formData.id = id;

		var validationResult = validateForm( formName, formData );
		var missingHtmlParams = emailTemplateService.listMissingParams(
			  template = id
			, content  = ( formData.html_body ?: "" )
		);
		var missingTextParams = emailTemplateService.listMissingParams(
			  template = id
			, content  = ( formData.text_body ?: "" )
		);

		if ( missingHtmlParams.len() ) {
			validationResult.addError( "html_body", "cms:emailcenter.variables.missing.validation.error", [ missingHtmlParams.toList( ", " ) ] );
		}
		if ( missingTextParams.len() ) {
			validationResult.addError( "text_body", "cms:emailcenter.variables.missing.validation.error", [ missingTextParams.toList( ", " ) ] );
		}

		if ( validationResult.validated() ) {
			emailTemplateService.saveTemplate( id=id, template=formData, isDraft=( saveAction=="savedraft" ), forcePublication=true );

			messagebox.info( translateResource( "cms:emailcenter.customTemplates.template.saved.confirmation" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="emailcenter.customTemplates.preview", queryString="id=#id#" ) );
		}

		formData.validationResult = validationResult;
		messagebox.error( translateResource( "cms:datamanager.data.validation.error" ) );
		setNextEvent(
			  url           = event.buildAdminLink( linkTo="emailcenter.customTemplates.edit", queryString="id=#id#" )
			, persistStruct = formData
		);
	}

	function publishAction( event, rc, prc ) {
		_checkPermissions( event=event, key="edit" );
		_checkPermissions( event=event, key="publish" );

		_getTemplate( argumentCollection=arguments, allowDrafts=true );

		var id = rc.id ?: "";
		emailTemplateService.saveTemplate( id=id, template={}, isDraft=false, forcePublication=true );

		messagebox.info( translateResource( "cms:emailcenter.customTemplates.template.published.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="emailcenter.customTemplates.preview", queryString="id=#id#" ) );
	}

	function clone( event, rc, prc ) {
		_checkPermissions( event=event, key="add" );
		_getTemplate( argumentCollection=arguments, allowDrafts=true );

		var id = rc.id ?: "";

		prc.cloneRecordForm = customizationService.runCustomization(
			  objectName     = "email_template"
			, action         = "cloneRecordForm"
			, defaultHandler = "admin.datamanager._cloneRecordForm"
			, args = {
				  objectName        = "email_template"
				, cloneRecordAction = event.buildAdminLink( linkto="emailcenter.customTemplates.cloneAction" )
				, recordId          = id
				, draftsEnabled     = true
				, canSaveDraft      = true
				, canPublish        = false
				, cancelAction      = event.buildAdminLink( linkto="emailcenter.customTemplates" )
				, record            = prc.record
			  }
		);

		prc.pageTitle    = translateResource( uri="cms:emailcenter.customTemplates.clone.page.title", data=[ prc.record.name ] );
		prc.pageSubtitle = translateResource( uri="cms:emailcenter.customTemplates.clone.page.subtitle", data=[ prc.record.name ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.customTemplates.clone.page.breadcrumb", data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="emailCenter.customTemplates.clone", queryString="id=#id#" )
		);
	}

	function cloneAction( event, rc, prc ) {
		_checkPermissions( event=event, key="add" );
		_getTemplate( argumentCollection=arguments, allowDrafts=true );

		var id       = rc.id ?: "";
		var formName = "preside-objects.email_template.admin.clone";
		var formData = event.getCollectionForForm( formName );
		var validationResult = validateForm( formName, formData );

		if ( validationResult.validated() ) {
			var newId = cloningService.cloneRecord(
				  objectName = "email_template"
				, recordId   = id
				, data       = formData
				, isDraft    = true
			);

			event.audit(
				  action   = "clone"
				, type     = "emailtemplate"
				, recordId = newId
				, detail   = { isSystemEmail = false }
			);


			messagebox.info( translateResource( "cms:emailcenter.customTemplates.template.cloned.confirmation" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="emailcenter.customTemplates.preview", queryString="id=#newId#" ) );
		}

		formData.validationResult = validationResult;
		messagebox.error( translateResource( "cms:datamanager.data.validation.error" ) );
		setNextEvent(
			  url           = event.buildAdminLink( linkTo="emailcenter.customTemplates.clone", queryString="id=#id#" )
			, persistStruct = formData
		);
	}

	function deleteAction( event, rc, prc ) {
		_checkPermissions( event=event, key="delete" );

		runEvent(
			  event          = "admin.DataManager._deleteRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object       = "email_template"
				, postAction   = "emailCenter.customTemplates"
				, audit        = true
				, auditType    = "emailtemplate"
				, auditAction  = "deleteTemplate"
			}
		);
	}

	public void function configureLayout( event, rc, prc ) {
		_checkPermissions( event=event, key="configurelayout" );
		_getTemplate( argumentCollection=arguments, allowDrafts=true );

		var templateId = rc.id ?: "";

		prc.pageTitle    = translateResource( uri="cms:emailcenter.customTemplates.configureLayout.page.title"   , data=[ prc.template.name ] );
		prc.pageSubTitle = translateResource( uri="cms:emailcenter.customTemplates.configureLayout.page.subTitle", data=[ prc.template.name ] );

		prc.configForm = renderViewlet( event="admin.emailCenter.layouts._configForm", args={
			  layoutId   = prc.template.layout
			, templateId = templateId
			, formAction = event.buildAdminLink( linkTo='emailcenter.customTemplates.saveLayoutConfigurationAction' )
		} );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.customTemplates.configureLayout.breadcrumb.title"  , data=[ prc.template.name ] )
			, link  = event.buildAdminLink( linkTo="emailcenter.customTemplates.configureLayout", queryString="id=" & templateId )
		);
	}

	public void function saveLayoutConfigurationAction() {
		_checkPermissions( event=event, key="configurelayout" );

		rc.id = rc.template ?: "";

		_getTemplate( argumentCollection=arguments, allowDrafts=true );

		var templateId = rc.template ?: "";

		runEvent(
			  event          = "admin.emailCenter.layouts._saveConfiguration"
			, private        = true
			, prepostExempt  = true
			, eventArguments = {
				  successUrl = event.buildAdminLink( linkto="emailcenter.customTemplates.preview", queryString="id=" & templateId )
				, failureUrl = event.buildAdminLink( linkto="emailcenter.customTemplates.configureLayout", queryString="id=" & templateId )
				, layoutId   = prc.template.layout
				, templateId = templateId
			  }
		);
	}

	public void function settings( event, rc, prc ) {
		_checkPermissions( event=event, key="editSendOptions" );
		_getTemplate( argumentCollection=arguments, allowDrafts=true, fromVersionTable=false );

		var templateId = rc.id ?: "";
		prc.filterObject = rc.filterObject = emailRecipientTypeService.getFilterObjectForRecipientType( prc.template.recipient_type ?: "" );
		prc.anonymousOnly = !prc.filterObject.len();

		if ( prc.anonymousOnly ) {
			prc.formName = "preside-objects.email_template.configure.send";
		} else {
			prc.formName = formsService.getMergedFormName( "preside-objects.email_template.configure.send", "preside-objects.email_template.configure.send.methods" );
		}

		prc.formName = formsService.getMergedFormName( "preside-objects.email_template.admin.edit.settings", prc.formName );

		if ( prc.record.blueprint_filter.len() ) {
			var filterDescription = translateResource(
				  uri = "preside-objects.email_template:fieldset.filter.description.additional.filter"
				, data = [
					  "<strong>" & renderlabel( "rules_engine_condition", prc.record.blueprint_filter ) & "</strong>"
					, "<strong>" & renderLabel( "email_blueprint", prc.record.email_blueprint ) & "</strong>"
				  ]
			);
			prc.formAdditionalArgs = {
				  fields    = { recipient_filter = { preRulesEngineFilters = prc.record.blueprint_filter } }
				, fieldsets = { filter           = { description           = filterDescription   } }
			};
		}

		prc.pageTitle    = translateResource( uri="cms:emailcenter.customTemplates.settings.page.title"   , data=[ prc.template.name ] );
		prc.pageSubTitle = translateResource( uri="cms:emailcenter.customTemplates.settings.page.subTitle", data=[ prc.template.name ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.customTemplates.settings.breadcrumb.title"  , data=[ prc.template.name ] )
			, link  = event.buildAdminLink( linkTo="emailcenter.customTemplates.settings", queryString="id=" & templateId )
		);

		var interceptArgs = {
			  filterObject       = prc.filterObject
			, anonymousOnly      = prc.anonymousOnly
			, formName           = prc.formName
			, formAdditionalArgs = ( prc.formAdditionalArgs ?: {} )
		};
		announceInterception( "preRenderEmailTemplateSettingsForm", interceptArgs );

		prc.filterObject       = interceptArgs.filterObject;
		prc.anonymousOnly      = interceptArgs.anonymousOnly;
		prc.formName           = interceptArgs.formName;
		prc.formAdditionalArgs = interceptArgs.formAdditionalArgs;
	}

	public void function saveSettingsAction( event, rc, prc ) {
		_checkPermissions( event=event, key="editSendOptions" );
		_getTemplate( argumentCollection=arguments, allowDrafts=true, fromVersionTable=false );

		var id               = rc.id ?: "";
		var filterObject     = emailRecipientTypeService.getFilterObjectForRecipientType( prc.record.recipient_type ?: "" );
		var anonymousOnly    = !filterObject.len();
		var validationResult = validateForms();
		var formData         = event.getCollectionWithoutSystemVars();
		    formData.id      = id;

		if ( anonymousOnly ) {
			formData.sending_method = "auto";
		}

		if ( formData.sending_method == "scheduled" && formData.schedule_type == "repeat" ) {
			var scheduleValidationFormName = "preside-objects.email_template.repeat.schedule.form.for.validation";
			validationResult = validateForm(
				  formName         = scheduleValidationFormName
				, formData         = formdata
				, validationResult = validationResult
			);
		}

		if ( validationResult.validated() ) {
			emailTemplateService.saveTemplate( id=id, template=formData, isDraft=( IsTrue( prc.template._version_is_draft ?: false ) ) );
			emailTemplateService.updateScheduledSendFields( templateId=id );

			messagebox.info( translateResource( "cms:emailcenter.customTemplates.settings.saved.confirmation" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="emailcenter.customTemplates.preview", queryString="id=#id#" ) );
		}

		formData.validationResult = validationResult;
		messagebox.error( translateResource( "cms:datamanager.data.validation.error" ) );
		setNextEvent(
			  url           = event.buildAdminLink( linkTo="emailcenter.customTemplates.settings", queryString="id=#id#" )
			, persistStruct = formData
		);
	}

	public void function versionHistory( event, rc, prc ) {
		var id = rc.id ?: "";

		prc.record = dao.selectData( id=id, selectFields=[ "name" ] );
		if ( !prc.record.recordCount || systemEmailTemplateService.templateExists( id ) ) {
			messageBox.error( translateResource( uri="cms:emailcenter.customTemplates.record.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="emailCenter.customTemplates" ) );
		}
		prc.pageTitle    = translateResource( uri="cms:emailcenter.customTemplates.versionHistory.page.title"   , data=[ prc.record.name ] );
		prc.pageSubTitle = translateResource( uri="cms:emailcenter.customTemplates.versionHistory.page.subTitle", data=[ prc.record.name ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.customTemplates.versionHistory.breadcrumb"  , data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="emailCenter.customTemplates.versionHistory", queryString="id=" & id )
		);
	}

	public void function getRecordsForAjaxDataTables( event, rc, prc ) {
		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object        = "email_template"
				, gridFields    = "name,sending_method,send_date,schedule_type"
				, actionsView   = "admin.emailCenter/customTemplates._gridActions"
				, filter        = { "email_template.is_system_email" = false }
				, draftsEnabled = true
			}
		);
	}

	private string function _gridActions( event, rc, prc, args={} ) {
		args.id                = args.id ?: "";
		args.deleteRecordLink  = event.buildAdminLink( linkTo="emailCenter.customTemplates.deleteAction"  , queryString="id=" & args.id );
		args.previewRecordLink = event.buildAdminLink( linkTo="emailCenter.customTemplates.preview"       , queryString="id=" & args.id );
		args.editRecordLink    = event.buildAdminLink( linkTo="emailCenter.customTemplates.edit"          , queryString="id=" & args.id );
		args.viewHistoryLink   = event.buildAdminLink( linkTo="emailCenter.customTemplates.versionHistory", queryString="id=" & args.id );
		args.cloneLink         = event.buildAdminLink( linkTo="emailCenter.customTemplates.clone"         , queryString="id=" & args.id );
		args.deleteRecordTitle = translateResource( "cms:emailcenter.customTemplates.delete.record.link.title" );
		args.objectName        = "email_template";
		args.canClone          = hasCmsPermission( "emailCenter.customTemplates.add"   );
		args.canEdit           = hasCmsPermission( "emailCenter.customTemplates.edit"   );
		args.canDelete         = hasCmsPermission( "emailCenter.customTemplates.delete" );
		args.canViewHistory    = hasCmsPermission( "emailCenter.customTemplates.view"   );

		return renderView( view="/admin/emailCenter/customTemplates/_gridActions", args=args );
	}

	public void function getHistoryForAjaxDatatables( event, rc, prc ) {
		var id = rc.id ?: "";

		prc.record = dao.selectData( id=id, selectFields=[ "name as label" ] );
		if ( !prc.record.recordCount || systemEmailTemplateService.templateExists( id ) ) {
			event.notFound();
		}

		runEvent(
			  event          = "admin.DataManager._getRecordHistoryForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object     = "email_template"
				, recordId   = id
				, actionsView = "admin/emailCenter/customTemplates/_historyActions"
			}
		);
	}

	public void function logs( event, rc, prc ) {
		_getTemplate( argumentCollection=arguments, allowDrafts=true );

		var id = rc.id ?: "";

		prc.pageTitle    = translateResource( uri="cms:emailcenter.customTemplates.log.page.title", data=[ prc.record.name ] );
		prc.pageSubtitle = translateResource( uri="cms:emailcenter.customTemplates.log.page.subtitle", data=[ prc.record.name ] );
		prc.showClicks   = IsTrue( prc.template.track_clicks ?: "" );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.customTemplates.log.page.breadcrumb", data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="emailCenter.customTemplates.logs", queryString="id=#id#" )
		);
	}

	public void function stats( event, rc, prc ) {
		_getTemplate( argumentCollection=arguments, allowDrafts=true );

		var id = rc.id ?: "";

		prc.pageTitle    = translateResource( uri="cms:emailcenter.customTemplates.stats.page.title", data=[ prc.record.name ] );
		prc.pageSubtitle = translateResource( uri="cms:emailcenter.customTemplates.stats.page.subtitle", data=[ prc.record.name ] );
		prc.showClicks   = IsTrue( prc.template.track_clicks ?: "" );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.customTemplates.stats.page.breadcrumb", data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="emailCenter.customTemplates.stats", queryString="id=#id#" )
		);
	}

	public void function getLogsForAjaxDataTables( event, rc, prc ) {
		var useDistinct = len( rc.sFilterExpression ?: "" ) || len( rc.sSavedFilterExpression ?: "" );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object      = "email_template_send_log"
				, gridFields  = "recipient,subject,datecreated,sent,delivered,failed,opened,click_count"
				, actionsView = "admin.emailCenter.logs._logGridActions"
				, filter      = { "email_template_send_log.email_template" = ( rc.id ?: "" ) }
				, distinct    = useDistinct
			}
		);
	}

	public void function send( event, rc, prc ) {
		_checkPermissions( event=event, key="send" );
		_getTemplate( argumentCollection=arguments );

		var templateId = rc.id ?: "";

		if ( prc.record.sending_method != "manual" ) {
			setNextEvent( url=event.buildAdminLink( linkTo="emailCenter.customTemplates.preview", queryString="id=" & templateId ) );
		}

		prc.recipientCount = emailMassSendingService.getTemplateRecipientCount( templateId );

		if ( prc.recipientCount ) {
			prc.filterObject = emailRecipientTypeService.getFilterObjectForRecipientType( prc.template.recipient_type );
			prc.gridFields   = emailRecipientTypeService.getGridFieldsForRecipientType( prc.template.recipient_type );
		}

		prc.pageTitle    = translateResource( uri="cms:emailcenter.customTemplates.send.page.title", data=[ prc.record.name ] );
		prc.pageSubtitle = translateResource( uri="cms:emailcenter.customTemplates.send.page.subtitle", data=[ prc.record.name ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.customTemplates.send.page.breadcrumb", data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="emailCenter.customTemplates.send", queryString="id=#templateId#" )
		);
	}

	public void function getRecipientListForAjaxDataTables( event, rc, prc ) {
		_checkPermissions( event=event, key="read" );
		_getTemplate( argumentCollection=arguments, allowDrafts=true );

		var templateId   = rc.id ?: "";
		var hideAlreadySent = IsBoolean( rc.hideAlreadySent ?: "" ) ? rc.hideAlreadySent : true;

		var extraFilters = emailMassSendingService.getTemplateRecipientFilters( templateId, hideAlreadySent );
		var filterObject = emailRecipientTypeService.getFilterObjectForRecipientType( prc.template.recipient_type );
		var gridFields   = emailRecipientTypeService.getGridFieldsForRecipientType( prc.template.recipient_type );
		var addPreviewLink = IsTrue( rc.addPreviewLink ?: "" );

		if ( addPreviewLink ) {
			var actionsView = "admin.emailCenter.customTemplates._selectPreviewUserLink";
		} else {
			var actionsView = "admin.emailCenter.customTemplates._noActions";
		}

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object        = filterObject
				, gridFields    = gridFields.toList()
				, actionsView   = actionsView
				, draftsEnabled = false
				, extraFilters  = extraFilters
			}
		);
	}

	public void function getRecipientListForAjaxSelect( event, rc, prc ) {
		_checkPermissions( event=event, key="read" );
		_getTemplate( argumentCollection=arguments, allowDrafts=true );

		var templateId      = rc.id ?: "";
		var hideAlreadySent = IsBoolean( rc.hideAlreadySent ?: "" ) ? rc.hideAlreadySent : true;
		var extraFilters    = emailMassSendingService.getTemplateRecipientFilters( templateId, hideAlreadySent );
		var filterObject    = emailRecipientTypeService.getFilterObjectForRecipientType( prc.template.recipient_type );
		var orderBy         = rc.orderBy       ?: "label";
		var labelRenderer   = rc.labelRenderer ?: "";
		var useCache        = IsTrue( rc.useCache ?: "" );

		var records = dataManagerService.getRecordsForAjaxSelect(
			  objectName    = filterObject
			, maxRows       = rc.maxRows ?: 1000
			, searchQuery   = rc.q       ?: ""
			, savedFilters  = ListToArray( rc.savedFilters ?: "" )
			, extraFilters  = extraFilters
			, orderBy       = orderBy
			, ids           = ListToArray( rc.values ?: "" )
			, labelRenderer = labelRenderer
			, useCache      = useCache
		);

		event.renderData( type="json", data=records );
	}

	public void function sendAction( event, rc, prc ) {
		_checkPermissions( event=event, key="send" );
		_getTemplate( argumentCollection=arguments );

		var templateId = rc.id ?: "";

		if ( prc.record.sending_method != "manual" ) {
			setNextEvent( url=event.buildAdminLink( linkTo="emailCenter.customTemplates.preview", queryString="id=" & templateId ) );
		}

		var queuedCount = emailMassSendingService.queueSendout( templateId );
		messageBox.info( translateResource( uri="cms:emailcenter.customTemplates.send.success", data=[ NumberFormat( queuedCount ) ] ) );
		setNextEvent( url=event.buildAdminLink( linkTo="emailCenter.customTemplates.preview", queryString="id=" & templateId ) );
	}

	public void function exportAction( event, rc, prc ) {
		if ( !isFeatureEnabled( "dataexport" ) ) {
			event.notFound();
		}

		var templateId = rc.id ?: "";

		runEvent(
			  event          = "admin.DataManager._exportDataAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				extraFilters = [ { filter={ email_template=templateId } } ]
			  }
		);
	}

// VIEWLETS
	private string function _customTemplateTabs( event, rc, prc, args={} ) {
		var template        = prc.record ?: {};
		var layout          = emailLayoutService.getLayout( template.layout ?: "" );
		var recipientObject = emailRecipientTypeService.getFilterObjectForRecipientType( template.recipient_type );
		var canSaveDraft    = hasCmsPermission( "emailcenter.customtemplates.savedraft" );
		var canPublish      = hasCmsPermission( "emailcenter.customtemplates.publish"   );

		args.canEdit                = canSaveDraft || canPublish;
		args.canConfigureLayout     = IsTrue( layout.configurable ?: "" ) && hasCmsPermission( "emailcenter.customtemplates.configureLayout" );
		args.canEditSendOptions     = hasCmsPermission( "emailcenter.customtemplates.editSendOptions" );

		return renderView( view="/admin/emailCenter/customTemplates/_customTemplateTabs", args=args );
	}

	private string function _customTemplateActions( event, rc, prc, args={} ) {
		var templateId = rc.id ?: "";
		var template   = emailTemplateService.getTemplate( id=templateId, allowDrafts=true );
		if ( template.count() ) {
			args.isDraft       = IsTrue( template._version_is_draft );
			args.canSend       = !args.isDraft && template.sending_method == "manual" && hasCmsPermission( "emailcenter.customtemplates.send" );
			args.canPublish    = args.isDraft && hasCmsPermission( "emailCenter.customTemplates.publish"   );
			args.canSendTest   = true;
			args.canDelete     = hasCmsPermission( "emailcenter.customtemplates.delete" );
			args.canClone      = hasCmsPermission( "emailcenter.customtemplates.add" );

			if ( args.canSend || args.canDelete || args.canClone || args.canPublish ) {
				return renderView( view="/admin/emailCenter/customTemplates/_customTemplateActions", args=args );
			}
		}

		return "";
	}

	private string function _customTemplateNotices( event, rc, prc, args={} ) {
		var templateId = rc.id ?: "";
		var template   = emailTemplateService.getTemplate( id=templateId, allowDrafts=true );

		if ( template.count() ) {
			args.isDraft       = IsTrue( template._version_is_draft );
			args.sendMethod    = template.sending_method ?: "";
			args.scheduleType  = template.schedule_type ?: "";

			if ( !args.isDraft  ) {
				if ( args.sendMethod == "scheduled" ){
					args.sendDate = args.scheduleType == "repeat" ? ( template.schedule_next_send_date ?: "" ) : ( template.schedule_date ?: "" );

					if ( IsDate( args.sendDate ) ) {
						if ( args.sendDate <= Now() ) {
							args.sent   = emailTemplateService.getSentCount( templateId );
							args.queued = emailTemplateService.getQueuedCount( templateId );
						} else {
							args.estimatedSendCount = emailMassSendingService.getTemplateRecipientCount( templateId );
						}
					}
				} else {
					args.sent   = emailTemplateService.getSentCount( templateId );
					args.queued = emailTemplateService.getQueuedCount( templateId );
				}

				if ( Val( args.queued ?: "" ) ) {
					args.canCancel = hasCmsPermission( "emailcenter.customtemplates.cancelsend" );
					if ( args.canCancel ) {
						args.cancelLink   = event.buildAdminLink( linkto="emailcenter.customtemplates.cancelSendAction", queryString="id=" & templateId );
						args.cancelPrompt = translateResource( "cms:emailcenter.customtemplates.cancel.send.prompt" );
						args.cancelSend   = translateResource( "cms:emailcenter.customtemplates.cancel.send.link"   );
					}
				}
			}

			return renderView( view="/admin/emailCenter/customTemplates/_customTemplateNotices", args=args );
		}

		return "";
	}

// private utility
	private void function _checkPermissions( required any event, required string key ) {
		if ( !hasCmsPermission( "emailCenter.customTemplates." & arguments.key ) ) {
			event.adminAccessDenied();
		}
	}

	private any function _getTemplate( event, rc, prc, allowDrafts=false, fromVersionTable=arguments.allowDrafts ) {
		var id      = rc.id ?: "";
		var version = Val( rc.version ?: "" );

		prc.record = prc.template = emailTemplateService.getTemplate(
			  id               = id
			, allowDrafts      = arguments.allowDrafts
			, version          = arguments.allowDrafts ? version : 0
			, fromVersionTable = arguments.fromVersionTable
		);

		if ( !prc.record.count() || systemEmailTemplateService.templateExists( id ) ) {
			messageBox.error( translateResource( uri="cms:emailcenter.customTemplates.record.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="emailCenter.customTemplates" ) );
		}
	}

	private string function _getTestSendFormName( event, rc, prc ) {
		var filterObject  = emailRecipientTypeService.getFilterObjectForRecipientType( prc.template.recipient_type );

		if ( !isEmpty( filterObject ) ) {
			var labelRenderer = presideObjectService.getObjectAttribute( filterObject, "labelRenderer" );
		} else {
			var labelRenderer = "";
		}

		var orderBy       = "label";
		var cacheBuster   = createuuid();
		var preFetchUrl   = event.buildAdminLink(
			  linkTo      = "emailCenter.customTemplates.getRecipientListForAjaxSelect"
			, querystring = "id=#prc.template.id#&maxRows=100&object=#filterObject#&prefetchCacheBuster=#cacheBuster#&orderBy=#orderBy#&labelRenderer=#labelRenderer#"
		);
		var remoteUrl     = event.buildAdminLink(
			  linkTo      = "emailCenter.customTemplates.getRecipientListForAjaxSelect"
			, querystring = "id=#prc.template.id#&object=#filterObject#&orderBy=#orderBy#&labelRenderer=#labelRenderer#&q=%QUERY"
		);

		return formsService.createForm( basedOn="email.test.send.test", generator=function( formDefinition ){
			if( !isEmpty( filterObject ) ){
				formDefinition.modifyField(
					  name        = "recipient"
					, fieldset    = "default"
					, tab         = "default"
					, object      = filterObject
					, preFetchUrl = preFetchUrl
					, remoteUrl   = remoteUrl
				);
			} else{
				formDefinition.modifyField(
					  name     = "recipient"
					, fieldset = "default"
					, tab      = "default"
					, control  = "hidden"
					, required = false
				)
			}
		} )
	}

	private struct function _getAdditionalAddEditFormArgs( event, rc, prc ) {
		var emailSettings = getSystemCategorySettings( "email" );

		return { fields = { save_content_expiry={
			  maxValue     = Val( emailSettings.max_content_expiry     ?: 90 )
			, defaultValue = Val( emailSettings.default_content_expiry ?: 90 )
		} } };
	}

}