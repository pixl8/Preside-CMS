component extends="preside.system.base.AdminHandler" {

	property name="emailTemplateService"       inject="emailTemplateService";
	property name="systemEmailTemplateService" inject="systemEmailTemplateService";
	property name="emailLayoutService"         inject="emailLayoutService";
	property name="dao"                        inject="presidecms:object:email_template";
	property name="messageBox"                 inject="coldbox:plugin:messageBox";


	function prehandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		_checkPermissions( event=event, key="read" );

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

		prc.canPublish   = hasCmsPermission( "emailCenter.customTemplates.saveDraft" );
		prc.canSaveDraft = hasCmsPermission( "emailCenter.customTemplates.publish"   );

		runEvent(
			  event          = "admin.DataManager._addRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object            = "email_template"
				, errorAction       = "emailCenter.customTemplates.add"
				, addAnotherAction  = "emailCenter.customTemplates.add"
				, successAction     = "emailCenter.customTemplates.edit"
				, redirectOnSuccess = true
				, audit             = true
				, auditType         = "customEmailTemplates"
				, auditAction       = saveAction == "publish" ? "add_record" : "add_draft_record"
				, draftsEnabled     = true
				, canPublish        = prc.canPublish
				, canSaveDraft      = prc.canSaveDraft
			}
		);
	}

	function preview( event, rc, prc ) {
		var id      = rc.id ?: "";
		var version = Val( rc.version ?: "" );

		prc.record = dao.selectData(
			  filter             = { id=id }
			, fromVersionTable   = true
			, allowDraftVersions = true
			, specificVersion    = version
		);

		if ( !prc.record.recordCount || systemEmailTemplateService.templateExists( id ) ) {
			messageBox.error( translateResource( uri="cms:emailcenter.customTemplates.record.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="emailCenter.customTemplates" ) );
		}
		prc.record = queryRowToStruct( prc.record );

		prc.pageTitle    = translateResource( uri="cms:emailcenter.customTemplates.preview.page.title", data=[ prc.record.name ] );
		prc.pageSubtitle = translateResource( uri="cms:emailcenter.customTemplates.preview.page.subtitle", data=[ prc.record.name ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.customTemplates.preview.page.breadcrumb", data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="emailCenter.customTemplates.preview", queryString="id=#id#" )
		);
	}

	function edit( event, rc, prc ) {
		_checkPermissions( event=event, key="edit" );
		prc.canSaveDraft = hasCmsPermission( "emailCenter.customTemplates.saveDraft" );
		prc.canPublish   = hasCmsPermission( "emailCenter.customTemplates.publish"   );
		if ( !prc.canSaveDraft && !prc.canPublish ) {
			event.adminAccessDenied()
		}

		var id      = rc.id ?: "";
		var version = Val( rc.version ?: "" );

		prc.record = dao.selectData(
			  filter             = { id=id }
			, fromVersionTable   = true
			, allowDraftVersions = true
			, specificVersion    = version
		);

		if ( !prc.record.recordCount || systemEmailTemplateService.templateExists( id ) ) {
			messageBox.error( translateResource( uri="cms:emailcenter.customTemplates.record.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="emailCenter.customTemplates" ) );
		}
		prc.record = queryRowToStruct( prc.record );

		prc.pageTitle    = translateResource( uri="cms:emailcenter.customTemplates.edit.page.title", data=[ prc.record.name ] );
		prc.pageSubtitle = translateResource( uri="cms:emailcenter.customTemplates.edit.page.subtitle", data=[ prc.record.name ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.customTemplates.edit.page.breadcrumb", data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="emailCenter.customTemplates.edit", queryString="id=#id#" )
		);
	}
	function editAction( event, rc, prc ) {
		_checkPermissions( event=event, key="edit" );

		var id = rc.id ?: "";
		var saveAction = ( rc._saveAction ?: "savedraft" ) == "publish" ? "publish" : "savedraft";
		_checkPermissions( event=event, key=saveAction );

		prc.record = dao.selectData( filter={ id=id } );

		if ( !prc.record.recordCount || systemEmailTemplateService.templateExists( id ) ) {
			messageBox.error( translateResource( uri="cms:emailcenter.customTemplates.record.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="emailCenter.customTemplates" ) );
		}

		var formName         = "preside-objects.email_template.admin.edit";
		var formData         = event.getCollectionForForm( formName );
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

		runEvent(
			  event          = "admin.DataManager._editRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object            = "email_template"
				, errorAction       = "emailCenter.customTemplates.edit"
				, successUrl        = event.buildAdminLink( linkto="emailCenter.customTemplates" )
				, redirectOnSuccess = true
				, audit             = true
				, auditType         = "customEmailTemplates"
				, auditAction       = ( saveAction == "publish" ? "publish_record" : "save_draft" )
				, draftsEnabled     = true
				, canPublish        = hasCmsPermission( "emailCenter.customTemplates.saveDraft" )
				, canSaveDraft      = hasCmsPermission( "emailCenter.customTemplates.publish"   )
				, validationResult  = validationResult
			}
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
				, auditType    = "customEmailTemplates"
				, auditAction  = "delete_record"
			}
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
		_checkPermissions( event=event, key="read" );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object        = "email_template"
				, gridFields    = "name"
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

// VIEWLETS
	private string function _customTemplateTabs( event, rc, prc, args={} ) {
		var template     = prc.record ?: {};
		var layout       = emailLayoutService.getLayout( template.layout ?: "" );
		var canSaveDraft = hasCmsPermission( "emailcenter.customtemplates.savedraft" );
		var canPublish   = hasCmsPermission( "emailcenter.customtemplates.publish"   );

		args.canEdit            = canSaveDraft || canPublish;
		args.canConfigureLayout = IsTrue( layout.configurable ?: "" ) && hasCmsPermission( "emailcenter.customtemplates.configureLayout" );

		return renderView( view="/admin/emailCenter/customTemplates/_customTemplateTabs", args=args );
	}

// private utility
	private void function _checkPermissions( required any event, required string key ) {
		if ( !hasCmsPermission( "emailCenter.customTemplates." & arguments.key ) ) {
			event.adminAccessDenied();
		}
	}

}