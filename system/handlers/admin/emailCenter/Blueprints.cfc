component extends="preside.system.base.AdminHandler" {

	property name="dao"                       inject="presidecms:object:email_blueprint";
	property name="emailTemplateDao"          inject="presidecms:object:email_template";
	property name="emailLayoutService"        inject="emailLayoutService";
	property name="emailRecipientTypeService" inject="emailRecipientTypeService";
	property name="messageBox"                inject="messagebox@cbmessagebox";


	function prehandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "emailcenter" ) || !isFeatureEnabled( "customEmailTemplates" ) ) {
			event.notFound();
		}

		_checkPermissions( event=event, key="read" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:emailcenter.blueprints.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="emailCenter.Blueprints" )
		);

		prc.pageIcon = "envelope";
	}

	function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( "cms:emailcenter.blueprints.page.title" );
		prc.pageSubtitle = translateResource( "cms:emailcenter.blueprints.page.subtitle" );

		prc.canAdd    = hasCmsPermission( "emailCenter.blueprints.add"    );
		prc.canDelete = hasCmsPermission( "emailCenter.blueprints.delete" );
	}

	function add( event, rc, prc ) {
		_checkPermissions( event=event, key="add" );

		prc.pageTitle    = translateResource( "cms:emailcenter.blueprints.add.page.title" );
		prc.pageSubtitle = translateResource( "cms:emailcenter.blueprints.add.page.subtitle" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:emailcenter.blueprints.add.page.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="emailCenter.Blueprints.add" )
		);
	}
	function addAction( event, rc, prc ) {
		_checkPermissions( event=event, key="add" );

		runEvent(
			  event          = "admin.DataManager._addRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object            = "email_blueprint"
				, errorAction       = "emailCenter.Blueprints.add"
				, addAnotherAction  = "emailCenter.Blueprints.add"
				, successAction     = "emailCenter.Blueprints.preview"
				, redirectOnSuccess = true
				, audit             = true
				, auditType         = "emailblueprints"
				, auditAction       = "add_record"
				, draftsEnabled     = false
			}
		);
	}

	function preview( event, rc, prc ) {

		var id = rc.id ?: "";

		prc.record = dao.selectData( id=id );

		if ( !prc.record.recordCount ) {
			event.notFound();
		}
		for( var r in prc.record ) {
			prc.record = r;
		}


		prc.preview = {};
		prc.preview.html = emailLayoutService.renderLayout(
			  layout        = prc.record.layout
			, emailTemplate = ""
			, blueprint     = id
			, type          = "html"
			, subject       = "Test email subject"
			, body          = "<p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>"
		);
		prc.preview.text = emailLayoutService.renderLayout(
			  layout        = prc.record.layout
			, emailTemplate = ""
			, blueprint     = id
			, type          = "text"
			, subject       = "Test email subject"
			, body          = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
		);

		prc.pageTitle    = translateResource( uri="cms:emailcenter.blueprints.preview.page.title", data=[ prc.record.name ] );
		prc.pageSubtitle = translateResource( uri="cms:emailcenter.blueprints.preview.page.subtitle", data=[ prc.record.name ] );
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.blueprints.preview.page.breadcrumb", data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="emailCenter.Blueprints.preview" )
		);
	}

	function edit( event, rc, prc ) {
		_checkPermissions( event=event, key="edit" );

		var id      = rc.id ?: "";
		var version = Val( rc.version ?: "" );

		prc.record = dao.selectData(
			  filter             = { id=id }
			, fromVersionTable   = true
			, allowDraftVersions = true
			, specificVersion    = version
		);

		if ( !prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:emailcenter.blueprints.record.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="emailCenter.Blueprints" ) );
		}
		prc.record = queryRowToStruct( prc.record );

		prc.filterObject = rc.filterObject = emailRecipientTypeService.getFilterObjectForRecipientType( prc.record.recipient_type ?: "" );

		prc.pageTitle    = translateResource( uri="cms:emailcenter.blueprints.edit.page.title", data=[ prc.record.name ] );
		prc.pageSubtitle = translateResource( uri="cms:emailcenter.blueprints.edit.page.subtitle", data=[ prc.record.name ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.blueprints.edit.page.breadcrumb", data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="emailCenter.Blueprints.edit", queryString="id=#id#" )
		);
	}

	function editAction( event, rc, prc ) {
		_checkPermissions( event=event, key="edit" );

		var id = rc.id ?: "";

		prc.record = dao.selectData( id=id );

		if ( !prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:emailcenter.blueprints.record.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="emailCenter.blueprints" ) );
		}

		runEvent(
			  event          = "admin.dataManager._editRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object            = "email_blueprint"
				, errorAction       = "emailCenter.blueprints.edit"
				, successUrl        = event.buildAdminLink( linkto="emailCenter.blueprints.preview", queryString="id=#id#" )
				, redirectOnSuccess = true
				, audit             = true
				, auditType         = "emailblueprints"
				, auditAction       = "edit"
				, draftsEnabled     = false
			}
		);
	}

	public void function configureLayout( event, rc, prc ) {
		_checkPermissions( event=event, key="edit" );

		var id = rc.id ?: "";

		prc.record = dao.selectData(
			  filter             = { id=id }
			, allowDraftVersions = true
		);

		if ( !prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:emailcenter.blueprints.record.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="emailCenter.Blueprints" ) );
		}

		prc.pageTitle    = translateResource( uri="cms:emailcenter.blueprints.configureLayout.page.title"   , data=[ prc.record.name ] );
		prc.pageSubTitle = translateResource( uri="cms:emailcenter.blueprints.configureLayout.page.subTitle", data=[ prc.record.name ] );

		prc.configForm = renderViewlet( event="admin.emailCenter.layouts._configForm", args={
			  layoutId   = prc.record.layout
			, blueprint  = id
			, formAction = event.buildAdminLink( linkTo='emailcenter.blueprints.saveLayoutConfigurationAction' )
		} );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.blueprints.configureLayout.breadcrumb.title"  , data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="emailcenter.blueprints.configureLayout", queryString="id=" & id )
		);
	}

	public void function saveLayoutConfigurationAction() {
		_checkPermissions( event=event, key="edit" );

		var id = rc.blueprint ?: "";

		prc.record = dao.selectData(
			  filter             = { id=id }
			, allowDraftVersions = true
		);

		if ( !prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:emailcenter.blueprints.record.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="emailCenter.Blueprints" ) );
		}

		runEvent(
			  event          = "admin.emailCenter.layouts._saveConfiguration"
			, private        = true
			, prepostExempt  = true
			, eventArguments = {
				  successUrl = event.buildAdminLink( linkto="emailcenter.blueprints.preview", queryString="id=" & id )
				, failureUrl = event.buildAdminLink( linkto="emailcenter.blueprints.configureLayout", queryString="id=" & id )
				, layoutId   = prc.record.layout
				, blueprint  = id
			  }
		);
	}

	function deleteAction( event, rc, prc ) {
		_checkPermissions( event=event, key="delete" );

		var bluePrintInUse = emailTemplateDao.dataExists( filter={ email_blueprint=rc.id ?: "" } );

		if ( bluePrintInUse ) {
			messageBox.error( translateResource( uri="cms:emailcenter.blueprints.prevent.delete.warning" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="emailCenter.Blueprints" ) );
		}

		runEvent(
			  event          = "admin.DataManager._deleteRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object       = "email_blueprint"
				, postAction   = "emailCenter.Blueprints"
				, audit        = true
				, auditType    = "emailblueprints"
				, auditAction  = "delete_record"
			}
		);
	}

	public void function versionHistory( event, rc, prc ) {
		var id = rc.id ?: "";

		prc.record = dao.selectData( id=id, selectFields=[ "name" ] );
		if ( !prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:emailcenter.blueprints.record.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="emailCenter.Blueprints" ) );
		}
		prc.pageTitle    = translateResource( uri="cms:emailcenter.blueprints.versionHistory.page.title"   , data=[ prc.record.name ] );
		prc.pageSubTitle = translateResource( uri="cms:emailcenter.blueprints.versionHistory.page.subTitle", data=[ prc.record.name ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.blueprints.versionHistory.breadcrumb"  , data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="emailCenter.Blueprints.versionHistory", queryString="id=" & id )
		);
	}

	public void function getRecordsForAjaxDataTables( event, rc, prc ) {
		_checkPermissions( event=event, key="read" );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object        = "email_blueprint"
				, gridFields    = "name,datecreated,datemodified"
				, actionsView   = "admin.emailCenter/Blueprints._gridActions"
				, draftsEnabled = true
			}
		);
	}

	private string function _gridActions( event, rc, prc, args={} ) {
		args.id = args.id ?: "";

		var bluePrintInUse = emailTemplateDao.dataExists( filter = { email_blueprint=args.id } );

		args.deleteRecordLink  = event.buildAdminLink( linkTo="emailCenter.Blueprints.deleteAction"  , queryString="id=" & args.id );
		args.editRecordLink    = event.buildAdminLink( linkTo="emailCenter.Blueprints.edit"          , queryString="id=" & args.id );
		args.viewHistoryLink   = event.buildAdminLink( linkTo="emailCenter.Blueprints.versionHistory", queryString="id=" & args.id );
		args.previewRecordLink = event.buildAdminLink( linkTo="emailCenter.Blueprints.preview"       , queryString="id=" & args.id );
		args.deleteRecordTitle = translateResource( "cms:emailcenter.blueprints.delete.record.link.title" );
		args.objectName        = "email_blueprint";
		args.canEdit           = hasCmsPermission( "emailCenter.blueprints.edit"   );
		args.canDelete         = hasCmsPermission( "emailCenter.blueprints.delete" ) AND !bluePrintInUse;
		args.canViewHistory    = hasCmsPermission( "emailCenter.blueprints.view"   );

		return renderView( view="/admin/emailCenter/Blueprints/_gridActions", args=args );
	}

	public void function getHistoryForAjaxDatatables( event, rc, prc ) {
		var id = rc.id ?: "";

		prc.record = dao.selectData( id=id, selectFields=[ "name as label" ] );
		if ( !prc.record.recordCount ) {
			event.notFound();
		}

		runEvent(
			  event          = "admin.DataManager._getRecordHistoryForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object     = "email_blueprint"
				, recordId   = id
				, actionsView = "admin/emailCenter/Blueprints/_historyActions"
			}
		);
	}

// viewlets
	private string function _blueprintTabs( event, rc, prc, args={} ) {
		var blueprint = prc.record ?: {};
		var layout    = emailLayoutService.getLayout( blueprint.layout ?: "" );

		args.canEdit            = hasCmsPermission( "emailcenter.blueprints.edit" );
		args.canConfigureLayout = IsTrue( layout.configurable ?: "" ) && hasCmsPermission( "emailcenter.blueprints.configureLayout" );

		return renderView( view="/admin/emailCenter/blueprints/_blueprintTabs", args=args );
	}

// private utility
	private void function _checkPermissions( required any event, required string key ) {
		if ( !hasCmsPermission( "emailCenter.blueprints." & arguments.key ) ) {
			event.adminAccessDenied();
		}
	}

}