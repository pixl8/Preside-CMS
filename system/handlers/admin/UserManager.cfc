component extends="preside.system.base.AdminHandler" output=false {

	property name="presideObjectService" inject="presideObjectService";
	property name="securityService"      inject="adminSecurityService";
	property name="messageBox"           inject="coldbox:plugin:messageBox";
	property name="bCryptService"        inject="bCryptService";

	function prehandler( event, rc, prc ) output=false {
		super.preHandler( argumentCollection = arguments );

		if ( !event.hasAdminPermission( "usermanager" ) ) {
			event.adminAccessDenied();
		}

		if ( event.getCurrentAction() contains "role" ) {
			event.addAdminBreadCrumb(
				  title = translateResource( "cms:usermanager.rolespage.title" )
				, link  = event.buildAdminLink( linkTo="usermanager.roles" )
			);
		} elseif ( event.getCurrentAction() contains "user" ) {
			event.addAdminBreadCrumb(
				  title = translateResource( "cms:usermanager.userspage.title" )
				, link  = event.buildAdminLink( linkTo="usermanager.users" )
			);
		}
	}

	function roles( event, rc, prc ) output=false {}

	function getRolesForAjaxDataTables( event, rc, prc ) output=false {
		runEvent(
			  event          = "admin.DataManager.getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, eventArguments = {
				  object      = "security_role"
				, gridFields  = "label,description"
				, actionsView = "/admin/usermanager/_rolesGridActions"
			}
		);
	}

	function addRole( event, rc, prc ) output=false {
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:usermanager.addRole.page.title" )
			, link  = event.buildAdminLink( linkTo="usermanager.addRole" )
		);
	}
	function addRoleAction( event, rc, prc ) output=false {
		var newId = runEvent(
			  event          = "admin.DataManager.addRecordAction"
			, prePostExempt  = true
			, eventArguments = {
				  object            = "security_role"
				, errorAction       = "userManager.addRole"
				, redirectOnSuccess = false
			}
		);

		securityService.setGlobalPermissionsForRole(
			  roleId      = newId
			, permissions = ( rc.global_permissions ?: "" )
		);

		messageBox.info( translateResource( uri="cms:datamanager.roleAdded.confirmation" ) );
		if ( Val( rc._addanother ?: 0 ) ) {
			setNextEvent( url=event.buildAdminLink( linkTo="usermanager.addRole" ), persist="_addAnother" );
		} else {
			setNextEvent( url=event.buildAdminLink( linkTo="usermanager.roles" ) );
		}
	}

	function editRole( event, rc, prc ) output=false {
		prc.record = presideObjectService.selectData( objectName="security_role", filter={ id=rc.id ?: "" } );

		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:usermanager.roleNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="usermanager.roles" ) );
		}
		prc.record = queryRowToStruct( prc.record );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:usermanager.editRole.page.title", data=[ prc.record.label ] )
			, link  = event.buildAdminLink( linkTo="usermanager.editRole", queryString="id=#(rc.id ?: '')#" )
		);
	}
	function editRoleAction( event, rc, prc ) output=false {
		securityService.setGlobalPermissionsForRole(
			  roleId = ( rc.id ?: "" )
			, permissions = ( rc.global_permissions ?: "" )
		);

		runEvent(
			  event          = "admin.DataManager.editRecordAction"
			, prePostExempt  = true
			, eventArguments = {
				  object        = "security_role"
				, errorAction   = "userManager.editRole"
				, successAction = "userManager.roles"
			}
		);
	}

	function deleteRoleAction( event, rc, prc ) output=false {
		runEvent(
			  event          = "admin.DataManager.deleteRecordAction"
			, prePostExempt  = true
			, eventArguments = {
				  object     = "security_role"
				, postAction = "userManager.roles"
			}
		);
	}

	function users( event, rc, prc ) output=false {}
	function getUsersForAjaxDataTables( event, rc, prc ) output=false {
		runEvent(
			  event          = "admin.DataManager.getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, eventArguments = {
				  object          = "security_user"
				, gridFields      = "active,login_id,label,email_address"
				, actionsView     = "/admin/usermanager/_usersGridActions"
				, useMultiActions = false
			}
		);
	}

	function addUser( event, rc, prc ) output=false {
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:usermanager.addUser.page.title" )
			, link  = event.buildAdminLink( linkTo="usermanager.addUser" )
		);
	}
	function addUserAction( event, rc, prc ) output=false {
		if ( Len( rc.password ?: "" ) ) {
			rc.password = bCryptService.hashPw( rc.password ?: "" );
			if ( bCryptService.checkPw( rc.confirm_password, rc.password ) ) {
				rc.confirm_password = rc.password;
			}
		} else {
			// TEMPORARY CODE!!!
			rc.password = bCryptService.hashPw( "password" );
			rc.confirm_password = rc.password;
		}

		runEvent(
			  event          = "admin.DataManager.addRecordAction"
			, prePostExempt  = true
			, eventArguments = {
				  object           = "security_user"
				, errorAction      = "userManager.addUser"
				, successAction    = "userManager.users"
				, addAnotherAction = "userManager.addUser"
				, viewRecordAction = "userManager.editUser"
			}
		);

		runEvent( event="admin.dataManager.addRecordAction" );
	}

	function editUser( event, rc, prc ) output=false {
		prc.record = presideObjectService.selectData( objectName="security_user", filter={ id=rc.id ?: "" } );

		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:usermanager.userNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="usermanager.users" ) );
		}
		prc.record = queryRowToStruct( prc.record );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:usermanager.editUser.page.title", data=[ prc.record.label ] )
			, link  = event.buildAdminLink( linkTo="usermanager.editUser", queryString="id=#(rc.id ?: '')#" )
		);
	}
	function editUserAction( event, rc, prc ) output=false {
		if ( rc.id == event.getAdminUserId() ) {
			StructDelete( rc, "active" ); // ensure user cannot deactivate themselves!
		}

		runEvent(
			  event          = "admin.dataManager.editRecordAction"
			, prePostExempt  = true
			, eventArguments = {
				  object            = "security_user"
				, errorAction       = "userManager.editUser"
				, successAction     = "userManager.users"
				, mergeWithFormName = ( rc.id == event.getAdminUserId() ) ? "preside-objects.security_user.admin.edit.self" : ""
			}
		);
	}

	function deleteUserAction( event, rc, prc ) output=false {
		var id            = rc.id ?: "";
		var postActionUrl = event.buildAdminLink( linkTo="usermanager.users" );

		if ( id == event.getAdminUserId() ) {
			messageBox.error( translateResource( uri="cms:usermanager.userCannotDeleteSelf.error" ) );
			setNextEvent( url=postActionUrl );
		}

		var object = "security_user";
		var obj    = presideObjectService.getObject( object );
		var record = obj.selectData( selectField=['label'], filter={ id = id } );

		if ( !record.recordCount ) {
			messageBox.error( translateResource( uri="cms:usermanager.userNotFound.error" ) );
			setNextEvent( url=postActionUrl );
		}

		var blockers = presideObjectService.listForeignObjectsBlockingDelete( object, id );
		if ( ArrayLen( blockers ) ) {
			if ( obj.updateData( id=id, data = { active=0 } ) ) {
				messageBox.warn( translateResource( uri="cms:usermanager.userDeActivated.confirmation", data=[ record.label ] ) );
				setNextEvent( url=postActionUrl );
			}
		} else {
			if ( obj.deleteData( filter={ id = id } ) ) {
				messageBox.info( translateResource( uri="cms:usermanager.userDeleted.confirmation", data=[ record.label ] ) );
				setNextEvent( url=postActionUrl );
			}
		}

		messageBox.error( translateResource( uri="cms:usermanager.recordNotDeleted.unknown.error" ) );
		setNextEvent( url=postActionUrl );
	}

}