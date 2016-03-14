component output="false" extends="preside.system.base.AdminHandler" {

	property name="userDao"               inject="presidecms:object:security_user";
	property name="messageBox"            inject="coldbox:plugin:messageBox";
	property name="bCryptService"         inject="bCryptService";
	property name="passwordPolicyService" inject="passwordPolicyService";

	function prehandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		var secondaryNavItems = [];
		var currentEvent = event.getCurrentEvent();

		secondaryNavItems.append({
			  active = currentEvent == "admin.editProfile.index"
			, link   = event.buildAdminLink( "editProfile" )
			, title  = translateResource( uri="cms:editProfile.secondary.nav.title" )
			, icon   = "fa-user"
		});
		secondaryNavItems.append({
			  active = currentEvent == "admin.editProfile.updatePassword"
			, link   = event.buildAdminLink( "editProfile.updatePassword" )
			, title  = translateResource( uri="cms:editProfile.password.secondary.nav.title" )
			, icon   = "fa-key"
		});
		prc.secondaryNav = renderView( view="/admin/layout/secondaryNavigation", args={ items=secondaryNavItems } );
	}

	function index( event, rc, prc ) {
		prc.record = userDao.selectData( id=event.getAdminUserId() );
		prc.record = queryRowToStruct( prc.record );

		prc.pageIcon  = "user";
		prc.pageTitle = translateResource( uri="cms:editProfile.page.title" );

		var passwordPolicy = passwordPolicyService.getPolicy( "cms" );
		if ( Len( Trim( passwordPolicy.message ?: "" ) ) ) {
			prc.policyMessage = renderContent( "richeditor", passwordPolicy.message );
		}

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:editProfile.page.title" )
			, link  = event.buildAdminLink( linkTo="editProfile" )
		);
	}

	function editProfileAction( event, rc, prc ) {
		var userId   = event.getAdminUserId();
		var formName = "preside-objects.security_user.admin.edit.profile";
		var formData = event.getCollectionForForm( formName );

		formData.id = userId;
		var validationResult = validateForm( formName=formName, formData=formData );

		if ( !validationResult.validated() ) {
			messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
			var persist = formData;
			persist.validationResult = validationResult;

			setNextEvent( url=event.buildAdminLink( linkTo="editProfile" ), persistStruct=persist );
		}

		userDao.updateData( id=userId, data=formData, updateManyToManyRecords=true );

		messageBox.info( translateResource( uri="cms:editProfile.updated.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="" ) );
	}

	function updatePassword( event, rc, prc ) {
		var passwordPolicy = passwordPolicyService.getPolicy( "cms" );

		prc.pageIcon  = "key";
		prc.pageTitle = translateResource( uri="cms:editProfile.password.page.title" );

		if ( Len( Trim( passwordPolicy.message ?: "" ) ) ) {
			prc.policyMessage = renderContent( "richeditor", passwordPolicy.message );
		}
	}

	function updatePasswordAction( event, rc, prc ) {
		var userId   = event.getAdminUserId();
		var formName = "preside-objects.security_user.admin.update.password";
		var formData = event.getCollectionForForm( formName );

		formData.id = userId;
		var validationResult = validateForm( formName=formName, formData=formData );
		if ( !loginService.isPasswordCorrect( formData.existing_password ?: "" ) ) {
			validationResult.addError( "existing_password", translateResource( "cms:editProfile.password.incorrect.existing.password" ) )
		}

		if ( !validationResult.validated() ) {
			messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );

			setNextEvent( url=event.buildAdminLink( linkTo="editProfile.updatePassword" ), persistStruct={ validationResult=validationResult } );
		}

		formData.password = bCryptService.hashPw( formData.new_password ?: "" );
		formData.delete( "new_password" );
		formData.delete( "existing_password" );
		formData.delete( "confirm_password" );

		userDao.updateData( id=userId, data=formData, updateManyToManyRecords=false );

		messageBox.info( translateResource( uri="cms:editProfile.password.updated.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="editProfile" ) );
	}
}