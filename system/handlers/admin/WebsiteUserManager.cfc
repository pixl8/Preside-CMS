component extends="preside.system.base.AdminHandler" {

	property name="websitePermissionService"        inject="websitePermissionService";
	property name="websiteLoginService"             inject="websiteLoginService";
	property name="websiteUserImpersonationService" inject="websiteUserImpersonationService";
	property name="presideObjectService"            inject="presideObjectService";
	property name="messageBox"                      inject="messagebox@cbmessagebox";
	property name="passwordPolicyService"           inject="passwordPolicyService";

	function prehandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "websiteUsers" ) ) {
			event.notFound();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:websiteUserManager.userspage.title" )
			, link  = event.buildAdminLink( linkTo="websiteUserManager" )
		);
	}

	function index( event, rc, prc ) {
		_checkPermissions( event=event, key="websiteUserManager.navigate" );
		prc.canDelete = hasCmsPermission( "websiteUserManager.delete" );
	}

	function getUsersForAjaxDataTables( event, rc, prc ) {
		_checkPermissions( event=event, key="websiteUserManager.read" );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object          = "website_user"
				, gridFields      = "active,login_id,display_name,email_address,last_request_made"
				, actionsView     = "/admin/websiteUserManager/_usersGridActions"
				, useMultiActions = true
			}
		);
	}

	function addUser( event, rc, prc ) {
		_checkPermissions( event=event, key="websiteUserManager.add" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:websiteUserManager.addUser.page.title" )
			, link  = event.buildAdminLink( linkTo="websiteUserManager.addUser" )
		);
	}
	function addUserAction( event, rc, prc ) {
		_checkPermissions( event=event, key="websiteUserManager.add" );

		var object = "website_user";
		var newId  = runEvent(
			  event          = "admin.DataManager._addRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object            = object
				, errorAction       = "websiteUserManager.addUser"
				, redirectOnSuccess = false
				, audit             = true
				, auditType         = "websiteusermanager"
				, auditAction       = "add_website_user"
			}
		);

		var newRecordLink = event.buildAdminLink( linkTo="websiteUserManager.editUser", queryString="id=#newId#" );

		websitePermissionService.syncUserPermissions( userId=newId, permissions=ListToArray( rc.permissions ?: "" ) );

		messageBox.info( translateResource( uri="cms:datamanager.recordAdded.confirmation", data=[
			  translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object )
			, '<a href="#newRecordLink#">#( rc.display_name ?: '')#</a>'
		] ) );

		if ( Val( rc._addanother ?: 0 ) ) {
			setNextEvent( url=event.buildAdminLink( linkTo="websiteUserManager.addUser" ), persist="_addAnother" );
		} else {
			setNextEvent( url=event.buildAdminLink( linkTo="websiteUserManager" ) );
		}
	}

	function viewUser( event, rc, prc ) {
		_checkPermissions( event=event, key="websiteUserManager.read" );

		prc.record = presideObjectService.selectData( objectName="website_user", filter={ id=rc.id ?: "" } );

		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:websiteUserManager.userNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="websiteUserManager" ) );
		}
		prc.record = queryRowToStruct( prc.record );
		prc.record.permissions = websitePermissionService.listUserPermissions( userId = rc.id ?: "" ).toList();

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:websiteUserManager.viewUser.page.title", data=[ prc.record.display_name ] )
			, link  = event.buildAdminLink( linkTo="websiteUserManager.viewUser", queryString="id=#(rc.id ?: '')#" )
		);
	}

	function editUser( event, rc, prc ) {
		_checkPermissions( event=event, key="websiteUserManager.edit" );

		prc.record = presideObjectService.selectData( objectName="website_user", filter={ id=rc.id ?: "" } );

		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:websiteUserManager.userNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="websiteUserManager" ) );
		}
		prc.record = queryRowToStruct( prc.record );
		prc.record.permissions = websitePermissionService.listUserPermissions( userId = rc.id ?: "" ).toList();

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:websiteUserManager.editUser.page.title", data=[ prc.record.display_name ] )
			, link  = event.buildAdminLink( linkTo="websiteUserManager.editUser", queryString="id=#(rc.id ?: '')#" )
		);
	}

	function editUserAction( event, rc, prc ) {
		_checkPermissions( event=event, key="websiteUserManager.edit" );

		runEvent(
			  event          = "admin.dataManager._editRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object            = "website_user"
				, errorAction       = "websiteUserManager.editUser"
				, redirectOnSuccess = false
				, audit             = true
				, auditType         = "websiteusermanager"
				, auditAction       = "edit_website_user"

			}
		);

		websitePermissionService.syncUserPermissions( userId=rc.id ?: "", permissions=ListToArray( rc.permissions ?: "" ) );

		messageBox.info( translateResource( uri="cms:websiteUserManager.user.saved.confirmation", data=[ rc.display_name ?: "" ] ) );
		setNextEvent( url=event.buildAdminLink( linkTo="websiteUserManager" ) );
	}

	function changeUserPassword( event, rc, prc ) {
		_checkPermissions( event=event, key="websiteUserManager.edit" );

		prc.record = presideObjectService.selectData( objectName="website_user", filter={ id=rc.id ?: "" } );

		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:websiteUserManager.userNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="websiteUserManager" ) );
		}

		var passwordPolicy = passwordPolicyService.getPolicy( "website" );
		if ( Len( Trim( passwordPolicy.message ?: "" ) ) ) {
			prc.policyMessage = renderContent( "richeditor", passwordPolicy.message );
		}

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:websiteUserManager.changeUserPassword.page.title", data=[ prc.record.display_name ] )
			, link  = event.buildAdminLink( linkTo="websiteUserManager.changeUserPassword", queryString="id=#(rc.id ?: '')#" )
		);
	}

	function changeUserPasswordAction( event, rc, prc ) {
		_checkPermissions( event=event, key="websiteUserManager.edit" );

		prc.record = presideObjectService.selectData( objectName="website_user", filter={ id=rc.id ?: "" } );

		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:websiteUserManager.userNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="websiteUserManager" ) );
		}

		var formName         = "preside-objects.website_user.admin.change.password";
		var formData         = event.getCollectionForForm( formName );
		var validationResult = validateForm( formName, formData );

		if ( validationResult.validated() ) {
			websiteLoginService.changePassword( formData.password, prc.record.id );
			event.audit(
				  type     = "websiteusermanager"
				, action   = "change_website_user_password"
				, recordId = prc.record.id
			);
			messageBox.info( translateResource( uri="cms:websiteUserManager.userPassword.changed.confirmation", data=[ prc.record.display_name ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="websiteUserManager" ) );
		}

		var persist = formData;
		persist.validationResult = validationResult;

		setNextEvent( url=event.buildAdminLink( linkTo="websiteUserManager.changeUserPassword", queryString="id=#rc.id#" ), persistStruct=persist );
	}

	function deleteUserAction( event, rc, prc ) {
		_checkPermissions( event=event, key="websiteUserManager.delete" );

		runEvent(
			  event          = "admin.DataManager._deleteRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object     = "website_user"
				, postAction = "websiteUserManager"
				, audit             = true
				, auditType         = "websiteusermanager"
				, auditAction       = "delete_website_user"
			}
		);
	}

	function impersonateUserAction( event, rc, prc ) {
		_checkPermissions( event=event, key="websiteUserManager.impersonate" );

		var userId         = rc.id        ?: "";
		var targetUrl      = rc.targetUrl ?: event.buildLink( page="homepage", site=event.getSiteId(), forceDomain=true );
		var impersonateUrl = websiteUserImpersonationService.create( userId, targetUrl );

		setNextEvent( url=impersonateUrl );
	}

	function exportAction( event, rc, prc ) {
		_checkPermissions( event=event, key="websiteUserManager.read" );

		runEvent(
			  event          = "admin.DataManager._exportDataAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = { objectName="website_user" }
		);
	}

// private utility
	private void function _checkPermissions( required any event, required string key ) {
		if ( !hasCmsPermission( arguments.key ) ) {
			event.adminAccessDenied();
		}
	}

}