component extends="preside.system.base.AdminHandler" {

	property name="emailTemplateService"       inject="emailTemplateService";
	property name="systemEmailTemplateService" inject="systemEmailTemplateService";
	property name="emailRecipientTypeService"  inject="emailRecipientTypeService";
	property name="emailLayoutService"         inject="emailLayoutService";
	property name="emailMassSendingService"    inject="emailMassSendingService";
	property name="formsService"               inject="formsService";
	property name="dao"                        inject="presidecms:object:email_template";
	property name="blueprintDao"               inject="presidecms:object:email_blueprint";
	property name="messageBox"                 inject="coldbox:plugin:messageBox";


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

		prc.canPublish   = hasCmsPermission( "emailCenter.customTemplates.saveDraft" );
		prc.canSaveDraft = hasCmsPermission( "emailCenter.customTemplates.publish"   );

		if ( !prc.canPublish && !prc.canSaveDraft ) {
			event.adminAccessDenied();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:emailcenter.customTemplates.add.page.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="emailCenter.customTemplates.add" )
		);
	}
	function addAction( event, rc, prc ) {
		_checkPermissions( event=event, key="add" );

		var saveAction = ( rc._saveAction ?: "savedraft" ) == "publish" ? "publish" : "savedraft";
		_checkPermissions( event=event, key=saveAction );

		var formName         = "preside-objects.email_template.admin.add";
		var formData         = event.getCollectionForForm( formName );
		var validationResult = validateForm( formName, formData );

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

		var id      = rc.id ?: "";
		var version = Val( rc.version ?: "" );

		prc.pageTitle    = translateResource( uri="cms:emailcenter.customTemplates.preview.page.title", data=[ prc.record.name ] );
		prc.pageSubtitle = translateResource( uri="cms:emailcenter.customTemplates.preview.page.subtitle", data=[ prc.record.name ] );
		prc.preview      = emailTemplateService.previewTemplate( template=id, allowDrafts=true, version=version );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.customTemplates.preview.page.breadcrumb", data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="emailCenter.customTemplates.preview", queryString="id=#id#" )
		);
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
			emailTemplateService.saveTemplate( id=id, template=formData, isDraft=( saveAction=="savedraft" ) );

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
		_getTemplate( argumentCollection=arguments );

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

		_getTemplate( argumentCollection=arguments );

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

	public void function sendOptions( event, rc, prc ) {
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
			}
		}

		prc.pageTitle    = translateResource( uri="cms:emailcenter.customTemplates.sendoptions.page.title"   , data=[ prc.template.name ] );
		prc.pageSubTitle = translateResource( uri="cms:emailcenter.customTemplates.sendoptions.page.subTitle", data=[ prc.template.name ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.customTemplates.sendoptions.breadcrumb.title"  , data=[ prc.template.name ] )
			, link  = event.buildAdminLink( linkTo="emailcenter.customTemplates.sendoptions", queryString="id=" & templateId )
		);
	}

	public void function saveSendOptionsAction( event, rc, prc ) {
		_checkPermissions( event=event, key="editSendOptions" );
		_getTemplate( argumentCollection=arguments, allowDrafts=true, fromVersionTable=false );

		var id            = rc.id ?: "";
		var filterObject  = emailRecipientTypeService.getFilterObjectForRecipientType( prc.record.recipient_type ?: "" );
		var anonymousOnly = !filterObject.len();
		var formName      = "preside-objects.email_template.configure.send";

		if ( !anonymousOnly ) {
			formName = formsService.getMergedFormName( "preside-objects.email_template.configure.send", "preside-objects.email_template.configure.send.methods" );
		}

		var formData         = event.getCollectionForForm( formName );
		var validationResult = validateForm( formName, formData );

		if ( anonymousOnly ) {
			formData.sending_method = "auto";
		}

		if ( validationResult.validated() ) {
			emailTemplateService.saveTemplate( id=id, template=formData, isDraft=false );
			emailTemplateService.updateScheduledSendFields( templateId=id );

			messagebox.info( translateResource( "cms:emailcenter.customTemplates.send.options.saved.confirmation" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="emailcenter.customTemplates.preview", queryString="id=#id#" ) );
		}

		formData.validationResult = validationResult;
		messagebox.error( translateResource( "cms:datamanager.data.validation.error" ) );
		setNextEvent(
			  url           = event.buildAdminLink( linkTo="emailcenter.customTemplates.sendoptions", queryString="id=#id#" )
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
				, gridFields    = "name,email_blueprint"
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
		args.deleteRecordTitle = translateResource( "cms:emailcenter.customTemplates.delete.record.link.title" );
		args.objectName        = "email_template";
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

	public void function log( event, rc, prc ) {
		_getTemplate( argumentCollection=arguments );

		var id = rc.id ?: "";

		prc.pageTitle    = translateResource( uri="cms:emailcenter.customTemplates.log.page.title", data=[ prc.record.name ] );
		prc.pageSubtitle = translateResource( uri="cms:emailcenter.customTemplates.log.page.subtitle", data=[ prc.record.name ] );
		prc.showClicks   = IsTrue( prc.template.track_clicks ?: "" );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.customTemplates.log.page.breadcrumb", data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="emailCenter.customTemplates.log", queryString="id=#id#" )
		);
	}

	public void function getLogsForAjaxDataTables( event, rc, prc ) {
		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object        = "email_template_send_log"
				, gridFields    = "recipient,subject,datecreated,sent,delivered,failed,opened,click_count"
				, actionsView   = "admin.emailCenter.logs._logGridActions"
				, filter        = { "email_template_send_log.email_template" = ( rc.id ?: "" ) }
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
		_getTemplate( argumentCollection=arguments );

		var templateId   = rc.id ?: "";

		var extraFilters = emailMassSendingService.getTemplateRecipientFilters( templateId );
		var filterObject = emailRecipientTypeService.getFilterObjectForRecipientType( prc.template.recipient_type );
		var gridFields   = emailRecipientTypeService.getGridFieldsForRecipientType( prc.template.recipient_type );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object        = filterObject
				, gridFields    = gridFields.toList()
				, actionsView   = "admin.emailCenter.customTemplates._noActions"
				, draftsEnabled = false
				, extraFilters  = extraFilters
			}
		);
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

// VIEWLETS
	private string function _customTemplateTabs( event, rc, prc, args={} ) {
		var template        = prc.record ?: {};
		var layout          = emailLayoutService.getLayout( template.layout ?: "" );
		var recipientObject = emailRecipientTypeService.getFilterObjectForRecipientType( template.recipient_type );
		var canSaveDraft    = hasCmsPermission( "emailcenter.customtemplates.savedraft" );
		var canPublish      = hasCmsPermission( "emailcenter.customtemplates.publish"   );

		args.stats                  = renderViewlet( event="admin.emailCenter.templateStatsSummary", args={ templateId=template.id } );
		args.canEdit                = canSaveDraft || canPublish;
		args.canConfigureLayout     = IsTrue( layout.configurable ?: "" ) && hasCmsPermission( "emailcenter.customtemplates.configureLayout" );
		args.canEditSendOptions     = hasCmsPermission( "emailcenter.customtemplates.editSendOptions" );

		return renderView( view="/admin/emailCenter/customTemplates/_customTemplateTabs", args=args );
	}

	private string function _customTemplateActions( event, rc, prc, args={} ) {
		var templateId = rc.id ?: "";
		var template   = emailTemplateService.getTemplate( id=templateId, allowDrafts=false );

		if ( template.count() ) {
			args.canSend       = template.sending_method == "manual" && hasCmsPermission( "emailcenter.customtemplates.send" );
			args.scheduleType  = template.schedule_type ?: "";
			args.nextSendDate  = template.schedule_next_send_date ?: "";
			args.canDelete     = hasCmsPermission( "emailcenter.customtemplates.delete" );
			args.canToggleLock = hasCmsPermission( "emailcenter.customtemplates.lock" );

			if ( args.canSend || args.canDelete || args.canToggleLock || args.scheduleType == "repeat" ) {
				return renderView( view="/admin/emailCenter/customTemplates/_customTemplateActions", args=args );
			}
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

}