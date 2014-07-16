component extends="preside.system.base.AdminHandler" output=false {

	property name="presideObjectService" inject="presideObjectService";
	property name="messageBox"           inject="coldbox:plugin:messageBox";
	property name="bCryptService"        inject="bCryptService";

	function prehandler( event, rc, prc ) output=false {
		super.preHandler( argumentCollection = arguments );

		if ( event.getCurrentAction() contains "group" ) {
			event.addAdminBreadCrumb(
				  title = translateResource( "cms:usermanager.groupspage.title" )
				, link  = event.buildAdminLink( linkTo="usermanager.groups" )
			);
		} elseif ( event.getCurrentAction() contains "user" ) {
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
				, gridFields  = "label,description"
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
			}
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
			}
		);
	}

	function deleteGroupAction( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="groupmanager.delete" );

		runEvent(
			  event          = "admin.DataManager._deleteRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object     = "security_group"
				, postAction = "userManager.groups"
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
				, gridFields      = "active,login_id,known_as,email_address"
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
			  event          = "admin.DataManager._addRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object           = "security_user"
				, errorAction      = "userManager.addUser"
				, successAction    = "userManager.users"
				, addAnotherAction = "userManager.addUser"
				, viewRecordAction = "userManager.editUser"
			}
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

		if ( rc.id == event.getAdminUserId() ) {
			StructDelete( rc, "active" ); // ensure user cannot deactivate themselves!
		}

		runEvent(
			  event          = "admin.dataManager._editRecordAction"
			, private        = true
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
		_checkPermissions( event=event, key="usermanager.delete" );

		var id            = rc.id ?: "";
		var postActionUrl = event.buildAdminLink( linkTo="usermanager.users" );

		if ( id == event.getAdminUserId() ) {
			messageBox.error( translateResource( uri="cms:usermanager.userCannotDeleteSelf.error" ) );
			setNextEvent( url=postActionUrl );
		}

		var object = "security_user";
		var obj    = presideObjectService.getObject( object );
		var record = obj.selectData( selectField=['known_as'], filter={ id = id } );

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
				messageBox.info( translateResource( uri="cms:usermanager.userDeleted.confirmation", data=[ record.known_as ] ) );
				setNextEvent( url=postActionUrl );
			}
		}

		messageBox.error( translateResource( uri="cms:usermanager.recordNotDeleted.unknown.error" ) );
		setNextEvent( url=postActionUrl );
	}

// private utility
	private void function _checkPermissions( required any event, required string key ) output=false {
		if ( !hasPermission( arguments.key ) ) {
			event.adminAccessDenied();
		}
	}

}