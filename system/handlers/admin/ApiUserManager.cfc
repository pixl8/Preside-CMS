component extends="preside.system.base.AdminHandler" {

	property name="dao"             inject="presidecms:object:rest_user";
	property name="restUserService" inject="presideRestUserService";
	property name="messageBox"      inject="coldbox:plugin:messageBox";


	function prehandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		_checkPermissions( event=event, key="read" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:apiManager.breadcrumbTitle" )
			, link  = event.buildAdminLink( linkTo = "apimanager" )
		);

		event.addAdminBreadCrumb(
			  title = translateResource( "apiManager:breadcrumb" )
			, link  = event.buildAdminLink( linkTo="apiUserManager" )
		);

		prc.pageIcon = "users";
	}

	function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( "apiManager:page.title" );
		prc.pageSubtitle = translateResource( "apiManager:page.subtitle" );

		prc.canAdd    = hasCmsPermission( "apiManager.add"    );
		prc.canDelete = hasCmsPermission( "apiManager.delete" );
	}

	function add( event, rc, prc ) {
		_checkPermissions( event=event, key="add" );

		prc.pageTitle    = translateResource( "apiManager:add.page.title" );
		prc.pageSubtitle = translateResource( "apiManager:add.page.subtitle" );
		prc.pageIcon     = "user";

		event.addAdminBreadCrumb(
			  title = translateResource( "apiManager:add.page.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="apiUserManager.add" )
		);
	}
	function addAction( event, rc, prc ) {
		_checkPermissions( event=event, key="add" );

		var userId = runEvent(
			  event          = "admin.DataManager._addRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object            = "rest_user"
				, errorAction       = "apiUserManager.add"
				, redirectOnSuccess = false
				, audit             = true
				, auditType         = "apiManager"
				, auditAction       = "add_record"
				, draftsEnabled     = false
			}
		);
		var apis = ( rc.apis ?: "" ).listToArray();
		restUserService.syncApiAccessForUser( userId, apis );

		var newRecordLink = event.buildAdminLink( linkto="apiUserManager.edit", queryString="id=" & userId );
		messageBox.info( translateResource( uri="cms:datamanager.recordAdded.confirmation", data=[
			  translateResource( uri="preside-objects.rest_user:title.singular", defaultValue="rest_user" )
			, '<a href="#newRecordLink#">#event.getValue( name="name", defaultValue=translateResource( uri="cms:datamanager.record" ) )#</a>'
		] ) );

		if ( Val( event.getValue( name="_addanother", defaultValue=0 ) ) ) {
			setNextEvent( url=event.buildAdminLink( linkto="apiUserManager.add" ), persist="_addAnother" );
		} else {
			setNextEvent( url=event.buildAdminLink( linkto="apiUserManager.view", queryString="id=#userId#" ) );
		}
	}

	function view( event, rc, prc ) {
		_checkPermissions( event=event, key="edit" );

		var id = rc.id ?: "";

		prc.record = dao.selectData( id=id );
		if ( !prc.record.recordCount ) {
			messageBox.error( translateResource( uri="apiManager:record.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="apiUserManager" ) );
		}
		prc.record = queryRowToStruct( prc.record );
		prc.apis   = restUserService.getApiAccessForUser( id );
		prc.canEdit = _checkPermissions( event=event, key="edit", throwOnError=false );

		prc.pageTitle    = translateResource( uri="apiManager:view.page.title", data=[ prc.record.name ] );
		prc.pageSubtitle = translateResource( uri="apiManager:view.page.subtitle", data=[ prc.record.name ] );
		prc.pageIcon     = "user";


		event.addAdminBreadCrumb(
			  title = translateResource( uri="apiManager:view.page.breadcrumb", data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="apiUserManager.view", queryString="id=#id#" )
		);
	}

	function edit( event, rc, prc ) {
		_checkPermissions( event=event, key="edit" );

		var id = rc.id ?: "";

		prc.record = dao.selectData( id=id );
		if ( !prc.record.recordCount ) {
			messageBox.error( translateResource( uri="apiManager:record.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="apiUserManager" ) );
		}
		prc.record = queryRowToStruct( prc.record );

		rc.apis = restUserService.getApiAccessForUser( id ).toList();

		prc.pageTitle    = translateResource( uri="apiManager:edit.page.title", data=[ prc.record.name ] );
		prc.pageSubtitle = translateResource( uri="apiManager:edit.page.subtitle", data=[ prc.record.name ] );
		prc.pageIcon     = "user";

		event.addAdminBreadCrumb(
			  title = translateResource( uri="apiManager:edit.page.breadcrumb", data=[ prc.record.name ] )
			, link  = event.buildAdminLink( linkTo="apiUserManager.edit", queryString="id=#id#" )
		);
	}
	function editAction( event, rc, prc ) {
		_checkPermissions( event=event, key="edit" );

		var id = rc.id ?: "";

		prc.record = dao.selectData( filter={ id=id } );

		if ( !prc.record.recordCount ) {
			messageBox.error( translateResource( uri="apiManager:record.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="apiUserManager" ) );
		}

		runEvent(
			  event          = "admin.DataManager._editRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object            = "rest_user"
				, errorAction       = "apiUserManager.edit"
				, redirectOnSuccess = false
				, audit             = true
				, auditType         = "apiManager"
				, auditAction       = "edit"
				, draftsEnabled     = false
			}
		);

		var apis = ( rc.apis ?: "" ).listToArray();
		restUserService.syncApiAccessForUser( id, apis );

		messageBox.info( translateResource( uri="cms:datamanager.recordEdited.confirmation", data=[ translateResource( uri="preside-objects.rest_user:title.singular", defaultValue="rest_user" ) ] ) );
		setNextEvent( url=event.buildAdminLink( linkto="apiUserManager.view", queryString="id=#id#" ) );
	}

	function regenerateTokenAction( event, rc, prc ) {
		_checkPermissions( event=event, key="edit" );

		var id = rc.id ?: "";

		prc.record = dao.selectData( filter={ id=id } );

		if ( !prc.record.recordCount ) {
			messageBox.error( translateResource( uri="apiManager:record.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="apiUserManager" ) );
		}

		restUserService.regenerateToken( id );

		event.audit(
			  action   = "userTokenRegenerated"
			, type     = "apiManager"
			, recordId = id
			, detail   = {}
		);

		messageBox.info( translateResource( uri="apiManager:user.token.regenerated" ) );
		setNextEvent( url=event.buildAdminLink( linkto="apiUserManager.view", queryString="id=#id#" ) );
	}

	function deleteAction( event, rc, prc ) {
		_checkPermissions( event=event, key="delete" );

		runEvent(
			  event          = "admin.DataManager._deleteRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object       = "rest_user"
				, postAction   = "apiUserManager"
				, audit        = true
				, auditType    = "apiManager"
				, auditAction  = "delete_record"
			}
		);
	}

	function multiAction( event, rc, prc ) {
		var action = rc.multiAction ?: "";
		var ids    = rc.id          ?: "";

		switch( action ){

			case "delete":
				return deleteAction( argumentCollection = arguments );
			break;
		}
		messageBox.error( translateResource( "cms:datamanager.invalid.multirecord.action.error" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="apiUserManager" ) );
	}

	public void function getRecordsForAjaxDataTables( event, rc, prc ) {
		_checkPermissions( event=event, key="read" );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object        = "rest_user"
				, gridFields    = "name,description,datemodified"
				, actionsView   = "admin.apiUserManager._gridActions"

			}
		);
	}

	private string function _gridActions( event, rc, prc, args={} ) {
		args.id                = args.id ?: "";
		args.deleteRecordLink  = event.buildAdminLink( linkTo="apiUserManager.deleteAction"  , queryString="id=" & args.id );
		args.viewRecordLink    = event.buildAdminLink( linkTo="apiUserManager.view"          , queryString="id=" & args.id );
		args.editRecordLink    = event.buildAdminLink( linkTo="apiUserManager.edit"          , queryString="id=" & args.id );
		args.deleteRecordTitle = translateResource( "apiManager:delete.record.link.title" );
		args.objectName        = "rest_user";
		args.canEdit           = hasCmsPermission( "apiManager.edit"   );
		args.canDelete         = hasCmsPermission( "apiManager.delete" );

		return renderView( view="/admin/apiUserManager/_gridActions", args=args );
	}

// private utility
	private boolean function _checkPermissions( required any event, required string key, boolean throwOnError=true ) {
		var hasPermission = hasCmsPermission( "apiManager." & arguments.key );
		if ( !hasPermission && arguments.throwOnError ) {
			event.adminAccessDenied();
		}

		return hasPermission;
	}

}