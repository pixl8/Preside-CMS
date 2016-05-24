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
		if ( loginService.isTwoFactorAuthenticationEnabled() ) {
			secondaryNavItems.append({
				  active = currentEvent == "admin.editProfile.twoFactorAuthentication"
				, link   = event.buildAdminLink( "editProfile.twofactorauthentication" )
				, title  = translateResource( uri="cms:editProfile.twoFactorAuthentication.secondary.nav.title" )
				, icon   = "fa-user-secret"
			});
		}

		prc.secondaryNav = renderView( view="/admin/layout/secondaryNavigation", args={ items=secondaryNavItems } );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:editProfile.page.title" )
			, link  = event.buildAdminLink( linkTo="editProfile" )
		);
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

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:editProfile.password.page.title" )
			, link  = event.buildAdminLink( linkTo="editProfile.updatePassword" )
		);
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

	function twoFactorAuthentication( event, rc, prc ) {
		if ( !loginService.isTwoFactorAuthenticationEnabled() ) {
			setNextEvent( url=event.buildAdminLink( linkTo="editProfile" ) );
		}

		prc.pageIcon     = "user-secret";
		prc.pageTitle    = translateResource( uri="cms:editProfile.twofactorauthentication.page.title" );
		prc.pageSubtitle = translateResource( uri="cms:editProfile.twofactorauthentication.page.subTitle" );

		prc.enforced = IsTrue( getSystemSetting( "two-factor-auth", "admin_enforced" ) )
		prc.enabled  = prc.enforced || loginService.isTwoFactorAuthenticationEnabledForUser();

		if ( !prc.enforced && !prc.enabled ) {
			prc.doSetup = IsTrue( rc.setup ?: "" );
			if ( prc.doSetup ) {
				prc.authenticationKey = loginService.getTwoFactorAuthenticationKey();
				if ( !Len( Trim( prc.authenticationKey ) ) ) {
					prc.authenticationKey = loginService.generateTwoFactorAuthenticationKey();
				}

				prc.qrCode = loginService.getTwoFactorAuthenticationQrCodeImage( key=prc.authenticationKey, size=300 );
			}
		}

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:editProfile.twofactorauthentication.page.title" )
			, link  = event.buildAdminLink( linkTo="editProfile.twoFactorAuthentication" )
		);
	}

	function completeTwoFactorAuthSetupAction( event, rc, prc ) {
		if ( !loginService.isTwoFactorAuthenticationEnabled() ) {
			setNextEvent( url=event.buildAdminLink( linkTo="editProfile" ) );
		}

		var enforced = IsTrue( getSystemSetting( "two-factor-auth", "admin_enforced" ) )
		var enabled  = enforced || loginService.isTwoFactorAuthenticationEnabledForUser();

		if ( enforced || enabled ) {
			setNextEvent( url=event.buildAdminLink( linkTo="editProfile.twoFactorAuthentication" ) );
		}

		var formName         = "two-factor-auth.confirm.setup";
		var formData         = event.getCollectionForForm( formName );
		var validationResult = validateForm( formName, formData );
		var authToken        = formData.oneTimeToken ?: "";

		if ( validationResult.validated() ) {
			var authVerified = loginService.attemptTwoFactorAuthentication(
				  token     = authToken
				, ipAddress = event.getClientIp()
				, userAgent = event.getUserAgent()
			);

			if ( authVerified ) {
				loginService.enableTwoFactorAuthenticationForUser();
				messagebox.info( translateResource( "cms:editProfile.twofactorauthentication.setup.complete.confirmation" ) );
				setNextEvent( url=event.buildAdminLink( "editProfile.twoFactorAuthentication" ) );
			}

			validationResult.addError( "oneTimeToken", translateResource( "cms:editProfile.twofactorauthentication.setup.invalid.auth.code" ) );
			messagebox.error( translateResource( "cms:datamanager.data.validation.error" ) );
		}

		setNextEvent(
			  url           = event.buildAdminLink( linkTo="editProfile.twoFactorAuthentication", queryString="setup=true" )
			, persistStruct = { validationResult = validationResult }
		);
	}

	function disableTwoFactorAuthenticationAction( event, rc, prc ) {
		if ( !loginService.isTwoFactorAuthenticationEnabled() ) {
			setNextEvent( url=event.buildAdminLink( linkTo="editProfile" ) );
		}

		var enforced = IsTrue( getSystemSetting( "two-factor-auth", "admin_enforced" ) );

		loginService.disableTwoFactorAuthenticationForUser();

		if ( enforced || IsTrue( rc.reset ?: "" ) ) {
			if ( enforced ) {
				runEvent( "admin.login.logout" );
			}
			setNextEvent( url = event.buildAdminLink( linkTo="editProfile.twoFactorAuthentication", queryString="setup=true" ) );
		}
		setNextEvent( url = event.buildAdminLink( linkTo="editProfile.twoFactorAuthentication" ) );
	}
}