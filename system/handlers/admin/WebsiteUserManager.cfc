component extends="preside.system.base.AdminHandler" output=false {

	property name="presideObjectService" inject="presideObjectService";
	property name="messageBox"           inject="coldbox:plugin:messageBox";
	property name="bCryptService"        inject="bCryptService";

	function prehandler( event, rc, prc ) output=false {
		super.preHandler( argumentCollection = arguments );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:websiteusermanager.userspage.title" )
			, link  = event.buildAdminLink( linkTo="websiteusermanager" )
		);
	}

	function index( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="websiteusermanager.navigate" );
	}

	function getUsersForAjaxDataTables( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="websiteusermanager.read" );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object          = "website_user"
				, gridFields      = "active,login_id,display_name,email_address"
				, actionsView     = "/admin/websiteusermanager/_usersGridActions"
				, useMultiActions = false
			}
		);
	}

	function addUser( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="websiteusermanager.add" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:websiteusermanager.addUser.page.title" )
			, link  = event.buildAdminLink( linkTo="websiteusermanager.addUser" )
		);
	}
	function addUserAction( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="websiteusermanager.add" );

		runEvent(
			  event          = "admin.DataManager._addRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object           = "website_user"
				, errorAction      = "websiteUserManager.addUser"
				, successAction    = "websiteUserManager"
				, addAnotherAction = "websiteUserManager.addUser"
				, viewRecordAction = "websiteUserManager.editUser"
			}
		);
	}

	function editUser( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="websiteusermanager.edit" );

		prc.record = presideObjectService.selectData( objectName="website_user", filter={ id=rc.id ?: "" } );

		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:websiteusermanager.userNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="websiteusermanager" ) );
		}
		prc.record = queryRowToStruct( prc.record );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:websiteusermanager.editUser.page.title", data=[ prc.record.display_name ] )
			, link  = event.buildAdminLink( linkTo="websiteusermanager.editUser", queryString="id=#(rc.id ?: '')#" )
		);
	}

	function editUserAction( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="usermanager.edit" );

		runEvent(
			  event          = "admin.dataManager._editRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object            = "website_user"
				, errorAction       = "websiteUserManager.editUser"
				, successAction     = "websiteUserManager"
			}
		);
	}

	function deleteUserAction( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="websiteUserManager.delete" );

		runEvent(
			  event          = "admin.DataManager._deleteRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object     = "website_user"
				, postAction = "websiteUserManager"
			}
		);
	}

// private utility
	private void function _checkPermissions( required any event, required string key ) output=false {
		if ( !hasPermission( arguments.key ) ) {
			event.adminAccessDenied();
		}
	}

}