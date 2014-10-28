component output="false" extends="preside.system.base.AdminHandler" {

	property name="userDao"       inject="presidecms:object:security_user";
	property name="messageBox"    inject="coldbox:plugin:messageBox";
	property name="bCryptService" inject="bCryptService";

	function index( event, rc, prc ) output=false {
		prc.record = userDao.selectData( id=event.getAdminUserId() );
		prc.record = queryRowToStruct( prc.record );

		prc.pageIcon  = "user";
		prc.pageTitle = translateResource( uri="cms:editProfile.page.title" );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:editProfile.page.title" )
			, link  = event.buildAdminLink( linkTo="editProfile" )
		);
	}

	function editProfileAction( event, rc, prc ) output=false {
		var userId   = event.getAdminUserId();
		var formName = "preside-objects.security_user.admin.edit.profile";
		var formData = event.getCollectionForForm( formName );

		if ( Len( formData.password ?: "" ) ) {
			formData.password = bCryptService.hashPw( formData.password ?: "" );
			if ( bCryptService.checkPw( formData.confirm_password, formData.password ) ) {
				formData.confirm_password = formData.password;
			}
		} else {
			formData.delete( "password" );
			formData.delete( "confirm_password" );
		}

		formData.id = userId;
		var validationResult = validateForm( formName=formName, formData=formData );

		if ( not validationResult.validated() ) {
			messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
			var persist = formData;
			persist.validationResult = validationResult;
			setNextEvent( url=event.buildAdminLink( linkTo="editProfile", persistStruct=persist ) );
		}

		userDao.updateData( id=userId, data=formData, updateManyToManyRecords=true );

		messageBox.info( translateResource( uri="cms:editProfile.updated.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="" ) );
	}
}