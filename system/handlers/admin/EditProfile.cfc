component output="false" extends="preside.system.base.AdminHandler" {

	property name="userDao"               inject="presidecms:object:security_user";
	property name="messageBox"            inject="coldbox:plugin:messageBox";
	property name="bCryptService"         inject="bCryptService";
	property name="passwordPolicyService" inject="passwordPolicyService";

	function index( event, rc, prc ) output=false {
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

	function editProfileAction( event, rc, prc ) output=false {
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

		if ( Len( formData.password ?: "" ) ) {
			formData.password = bCryptService.hashPw( formData.password ?: "" );
		} else {
			formData.delete( "password" );
			formData.delete( "confirm_password" );
		}

		userDao.updateData( id=userId, data=formData, updateManyToManyRecords=true );

		messageBox.info( translateResource( uri="cms:editProfile.updated.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="" ) );
	}
}