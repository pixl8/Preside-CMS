component {

	property name="websiteLoginService"   inject="websiteLoginService";
	property name="passwordPolicyService" inject="passwordPolicyService";

// core events
	public void function attemptLogin( event, rc, prc ) output=false {
		announceInterception( "preAttemptLogin" );

		if ( websiteLoginService.isLoggedIn() && !websiteLoginService.isAutoLoggedIn() ) {
			setNextEvent( url=_getDefaultPostLoginUrl( argumentCollection=arguments ) );
		}
		var loginId      = rc.loginId  ?: "";
		var password     = rc.password ?: "";
		var postLoginUrl = websiteLoginService.getPostLoginUrl( explicitValue=rc.postLoginUrl ?: "", defaultValue=cgi.http_referer ?: "" );
		var rememberMe   = _getRememberMeAllowed() && IsBoolean( rc.rememberMe ?: "" ) && rc.rememberMe;
		var loggedIn     = websiteLoginService.login(
			  loginId              = loginId
			, password             = password
			, rememberLogin        = rememberMe
			, rememberExpiryInDays = _getRememberMeExpiry()
		);

		if ( loggedIn ) {
			announceInterception( "onLoginSuccess"  );

			websiteLoginService.clearPostLoginUrl();
			setNextEvent( url=postLoginUrl );
		}

		announceInterception( "onLoginFailure"  );

		websiteLoginService.setPostLoginUrl( postLoginUrl );
		var persist = event.getCollectionWithoutSystemVars();
		    persist.message = "LOGIN_FAILED";

		setNextEvent( url=event.buildLink( page="login" ), persistStruct=persist );
	}

	public void function logout( event, rc, prc ) output=false {
		websiteLoginService.logout();
		setNextEvent( url=_getDefaultPostLogoutUrl( argumentCollection=arguments ) );
	}

	public void function sendResetInstructions( event, rc, prc ) output=false {
		if ( websiteLoginService.sendPasswordResetInstructions( rc.loginId ?: "" ) ) {
			setNextEvent( url=event.buildLink( page="forgotten_password" ), persistStruct={
				  message = "PASSWORD_RESET_INSTRUCTIONS_SENT"
				, loginId = ( rc.loginId ?: "" )
			} );
		}

		setNextEvent( url=event.buildLink( page="forgotten_password" ), persistStruct={
			message = "LOGINID_NOT_FOUND"
		} );
	}

	public void function resetPasswordAction( event, rc, prc ) output=false {
		var pw           = rc.password             ?: "";
		var confirmation = rc.passwordConfirmation ?: "";
		var token        = rc.token                ?: "";

		if ( !websiteLoginService.validateResetPasswordToken( rc.token ?: "" ) ) {
			setNextEvent( url=event.buildLink( page="forgotten_password" ), persistStruct={
				message = "INVALID_RESET_TOKEN"
			} );
		}

		if ( !Len( Trim( pw ) ) ) {
			setNextEvent( url=event.buildLink( page="reset_password" ), persistStruct={
				  message = "EMPTY_PASSWORD"
				, token   = token
			} );
		}

		if ( pw != confirmation ) {
			setNextEvent( url=event.buildLink( page="reset_password" ), persistStruct={
				  message = "PASSWORDS_DO_NOT_MATCH"
				, token   = token
			} );
		}

		if ( !passwordPolicyService.passwordMeetsPolicy( "website", pw ) ) {
			setNextEvent( url=event.buildLink( page="reset_password" ), persistStruct={
				  message = "PASSWORD_NOT_STRONG_ENOUGH"
				, token   = token
			} );
		}

		if ( websiteLoginService.resetPassword( token=token, password=pw ) ) {
			setNextEvent( url=event.buildLink( page="login" ), persistStruct={
				message = "PASSWORD_RESET"
			} );
		}

		setNextEvent( url=event.buildLink( page="reset_password" ), persistStruct={
			  message = "UNKNOWN_ERROR"
			, token   = token
		} );

	}

// page type viewlets
	private string function loginPage( event, rc, prc, args={} ) output=false {
		if ( websiteLoginService.isLoggedIn() && ( !websiteLoginService.isAutoLoggedIn() || _isDirectLoginPageRequest( event ) ) ) {
			setNextEvent( url=_getDefaultPostLoginUrl( argumentCollection=arguments ) );
		}

		args.allowRememberMe = _getRememberMeAllowed();
		args.postLoginUrl    = websiteLoginService.getPostLoginUrl( explicitValue=rc.postLoginUrl ?: "", defaultValue=event.getCurrentUrl() );
		args.loginId         = args.loginId      ?: ( rc.loginId      ?: "" );
		args.rememberMe      = args.rememberMe   ?: ( rc.rememberMe   ?: "" );
		args.message         = args.message      ?: ( rc.message      ?: "" );

		return renderView( view="/login/loginPage", presideObject="login", id=event.getCurrentPageId(), args=args );
	}

	private string function forgottenPassword( event, rc, prc, args={} ) output=false {
		if ( websiteLoginService.isLoggedIn() ) {
			setNextEvent( url=_getDefaultPostLoginUrl( argumentCollection=arguments ) );
		}

		args.postLoginUrl = websiteLoginService.getPostLoginUrl( explicitValue=rc.postLoginUrl ?: "", defaultValue=cgi.http_referer ?: "" );

		return renderView( view="/login/forgottenPassword", presideObject="forgotten_password", id=event.getCurrentPageId(), args=args );
	}

	private string function resetPassword( event, rc, prc, args={} ) output=false {
		if ( websiteLoginService.isLoggedIn() ) {
			setNextEvent( url=_getDefaultPostLoginUrl( argumentCollection=arguments ) );
		}

		if ( !websiteLoginService.validateResetPasswordToken( rc.token ?: "" ) ) {
			setNextEvent( url=event.buildLink( page="forgotten_password" ), persistStruct={
				message = "INVALID_RESET_TOKEN"
			} );
		}

		var passwordPolicy = passwordPolicyService.getPolicy( "website" );

		if ( Len( Trim( passwordPolicy.message ?: "" ) ) ) {
			prc.policyMessage = renderContent( "richeditor", passwordPolicy.message );
		}

		return renderView( view="/login/resetPassword", presideObject="reset_password", id=event.getCurrentPageId(), args=args );
	}

// private helpers
	private string function _getDefaultPostLoginUrl( event, rc, prc ) output=false {
		var defaultPage = getSystemSetting( "website_users", "default_post_login_page", "" );

		if ( Len( Trim( defaultPage ) ) ) {
			return event.buildLink( page=defaultPage );
		}
		return "/";
	}

	private string function _getDefaultPostLogoutUrl( event, rc, prc ) output=false {
		var defaultPage = getSystemSetting( "website_users", "default_post_logout_page", "" );

		if ( Len( Trim( defaultPage ) ) ) {
			return event.buildLink( page=defaultPage );
		}
		return "/";
	}

	private boolean function _getRememberMeAllowed() output=false {
		var allowed = getSystemSetting( "website_users", "allow_remember_me", true );
		return IsBoolean( allowed ) && allowed;
	}

	private boolean function _getRememberMeExpiry() output=false {
		return getSystemSetting( "website_users", "remember_me_expiry", 90 );
	}

	private boolean function _isDirectLoginPageRequest( event ) {
		var currentUrl = event.getSiteUrl() & event.getCurrentUrl( includeQueryString=false );
		var loginPage  = event.buildLink( page="login" );

		return currentUrl == loginPage;
	}

}