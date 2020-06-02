component extends="preside.system.base.AdminHandler" {

	property name="presideObjectService" inject="presideObjectService";
	property name="loginService"         inject="loginService";
	property name="permissionService"    inject="permissionService";
	property name="messageBox"           inject="messagebox@cbmessagebox";

	function prehandler( event, rc, prc ) output=false {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "cmsUserManager" ) ) {
			event.notFound();
		}

		if ( event.getCurrentAction() contains "group" ) {
			event.addAdminBreadCrumb(
				  title = translateResource( "cms:usermanager.groupspage.title" )
				, link  = event.buildAdminLink( linkTo="usermanager.groups" )
			);
		} else if ( event.getCurrentAction() contains "user" ) {
			event.addAdminBreadCrumb(
				  title = translateResource( "cms:usermanager.userspage.title" )
				, link  = event.buildAdminLink( linkTo="usermanager.users" )
			);
		}
	}

	function groups( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="groupmanager.navigate" );
	}

	function getGroupsForAjaxDataTables( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="groupmanager.read" );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object      = "security_group"
				, gridFields  = "label,description,is_catch_all"
				, actionsView = "/admin/usermanager/_groupsGridActions"
			}
		);
	}

	function addGroup( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="groupmanager.add" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:usermanager.addGroup.page.title" )
			, link  = event.buildAdminLink( linkTo="usermanager.addGroup" )
		);
	}
	function addGroupAction( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="groupmanager.add" );

		var newId = runEvent(
			  event          = "admin.DataManager._addRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object           = "security_group"
				, errorAction      = "userManager.addGroup"
				, successAction    = "usermanager.groups"
				, addAnotherAction = "usermanager.addGroup"
				, viewRecordAction = "userManager.editGroup"
				, audit            = true
				, auditAction      = "add_user_group"
				, auditType        = "usermanager"
			}
		);
	}

	function viewGroup( event, rc, prc ) {
		_checkPermissions( event=event, key="groupmanager.read" );

		prc.record = presideObjectService.selectData( objectName="security_group", filter={ id=rc.id ?: "" } );

		if ( !prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:usermanager.groupNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="usermanager.groups" ) );
		}

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:usermanager.viewGroup.page.title", data=[ prc.record.label ] )
			, link  = event.buildAdminLink( linkTo="usermanager.viewGroup", queryString="id=#rc.id#" )
		);
	}

	function editGroup( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="groupmanager.edit" );

		prc.record = presideObjectService.selectData( objectName="security_group", filter={ id=rc.id ?: "" } );

		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:usermanager.groupNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="usermanager.groups" ) );
		}
		prc.record = queryRowToStruct( prc.record );

		if ( IsTrue( prc.record.is_catch_all ?: "" ) ) {
			prc.mergeWithFormName = "preside-objects.security_group.admin.edit.catchall"
		}

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:usermanager.editGroup.page.title", data=[ prc.record.label ] )
			, link  = event.buildAdminLink( linkTo="usermanager.editGroup", queryString="id=#(rc.id ?: '')#" )
		);
	}
	function editGroupAction( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="groupmanager.edit" );

		runEvent(
			  event          = "admin.DataManager._editRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object        = "security_group"
				, errorAction   = "userManager.editGroup"
				, successAction = "userManager.groups"
				, audit            = true
				, auditAction      = "edit_user_group"
				, auditType        = "usermanager"
			}
		);
	}

	function deleteGroupAction( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="groupmanager.delete" );

		for( var groupid in ListToArray( rc.id ?: "" ) ) {
			if ( permissionService.isCatchAllGroup( groupid ) ) {
				messageBox.error( translateResource( "cms:usermanager.cannot.delete.catch.all" ) );
				setNextEvent( url=event.buildAdminLink( linkto="usermanager.groups" ) );
			}
		}

		runEvent(
			  event          = "admin.DataManager._deleteRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object      = "security_group"
				, postAction  = "userManager.groups"
				, audit       = true
				, auditAction = "delete_user_group"
				, auditType   = "usermanager"
			}
		);
	}

	function users( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="usermanager.navigate" );
	}
	function getUsersForAjaxDataTables( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="usermanager.read" );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object          = "security_user"
				, gridFields      = "active,login_id,known_as,email_address,last_request_made"
				, actionsView     = "/admin/usermanager/_usersGridActions"
				, useMultiActions = false
			}
		);
	}

	function addUser( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="usermanager.add" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:usermanager.addUser.page.title" )
			, link  = event.buildAdminLink( linkTo="usermanager.addUser" )
		);
	}
	function addUserAction( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="usermanager.add" );

		var newUserId = runEvent(
			  event          = "admin.DataManager._addRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object           = "security_user"
				, errorAction      = "userManager.addUser"
				, redirectOnSuccess = false
				, audit             = true
				, auditAction       = "add_user"
				, auditType         = "usermanager"
			}
		);

		if ( IsBoolean( rc.send_welcome ?: "" ) && rc.send_welcome ) {
			loginService.sendWelcomeEmail( newUserId, event.getAdminUserDetails().known_as, rc.welcome_message ?: "" );
		}

		var newRecordLink = event.buildAdminLink( linkTo="usermanager.editUser", queryString="id=#newUserId#" );
		messageBox.info( translateResource( uri="cms:datamanager.recordAdded.confirmation", data=[
			  translateResource( uri="preside-objects.security_user:title.singular", defaultValue="security_user" )
			, '<a href="#newRecordLink#">#( rc.known_as ?: "" )#</a>'
		] ) );

		if ( Val( rc._addanother ?: 0 ) ) {
			setNextEvent( url=event.buildAdminLink( linkTo="userManager.addUser" ), persist="_addAnother" );
		} else {
			setNextEvent( url=event.buildAdminLink( linkTo="userManager.users" ) );
		}
	}

	function viewUser( event, rc, prc ) {
		_checkPermissions( event=event, key="usermanager.read" );

		prc.record = presideObjectService.selectData(
			  objectName              = "security_user"
			, filter                  = { id=rc.id ?: "" }
			, includeAllFormulaFields = true );

		if ( !prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:usermanager.userNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="usermanager.users" ) );
		}

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:usermanager.viewUser.page.title", data=[ prc.record.known_as ] )
			, link  = event.buildAdminLink( linkTo="usermanager.viewUser", queryString="id=#(rc.id ?: '')#" )
		);
	}

	function editUser( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="usermanager.edit" );

		prc.record = presideObjectService.selectData( objectName="security_user", filter={ id=rc.id ?: "" } );

		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:usermanager.userNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="usermanager.users" ) );
		}
		prc.record = queryRowToStruct( prc.record );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:usermanager.editUser.page.title", data=[ prc.record.known_as ] )
			, link  = event.buildAdminLink( linkTo="usermanager.editUser", queryString="id=#(rc.id ?: '')#" )
		);
	}
	function editUserAction( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="usermanager.edit" );

		var userId = rc.id ?: "";

		if ( userId == event.getAdminUserId() ) {
			StructDelete( rc, "active" ); // ensure user cannot deactivate themselves!
		}

		if ( IsBoolean( rc.resend_welcome ?: "" ) && rc.resend_welcome ) {
			loginService.sendWelcomeEmail( userId, event.getAdminUserDetails().known_as, rc.welcome_message ?: "" );
		}

		runEvent(
			  event          = "admin.dataManager._editRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object            = "security_user"
				, errorAction       = "userManager.editUser"
				, successAction     = "userManager.users"
				, mergeWithFormName = ( userId == event.getAdminUserId() ) ? "preside-objects.security_user.admin.edit.self" : ""
				, audit             = true
				, auditAction       = "edit_user"
				, auditType         = "usermanager"
			}
		);
	}

	function deleteUserAction( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="usermanager.delete" );

		var id            = rc.id ?: "";
		var postActionUrl = event.buildAdminLink( linkTo="usermanager.users" );

		if ( id == event.getAdminUserId() ) {
			messageBox.error( translateResource( uri="cms:usermanager.userCannotDeleteSelf.error" ) );
			setNextEvent( url=postActionUrl );
		}

		var object = "security_user";
		var obj    = presideObjectService.getObject( object );
		var record = obj.selectData( id = id );

		if ( !record.recordCount ) {
			messageBox.error( translateResource( uri="cms:usermanager.userNotFound.error" ) );
			setNextEvent( url=postActionUrl );
		}

		var blockers = presideObjectService.listForeignObjectsBlockingDelete( object, id );
		if ( ArrayLen( blockers ) ) {
			if ( obj.updateData( id=id, data = { active=0 } ) ) {
				messageBox.warn( translateResource( uri="cms:usermanager.userDeActivated.confirmation", data=[ record.known_as ] ) );
				setNextEvent( url=postActionUrl );
			}
		} else {
			if ( obj.deleteData( filter={ id = id } ) ) {
				event.audit(
					  action   = "delete_user"
					, type     = "usermanager"
					, recordId = id
					, detail   = QueryRowToStruct( record )
				);
				messageBox.info( translateResource( uri="cms:usermanager.userDeleted.confirmation", data=[ record.known_as ] ) );
				setNextEvent( url=postActionUrl );
			}
		}

		messageBox.error( translateResource( uri="cms:usermanager.recordNotDeleted.unknown.error" ) );
		setNextEvent( url=postActionUrl );
	}

// private utility
	private void function _checkPermissions( required any event, required string key ) output=false {
		if ( !hasCmsPermission( arguments.key ) ) {
			event.adminAccessDenied();
		}
	}

}