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

		var allowResetPassword = websiteLoginService.allowResetPassword( rc.loginId ?: "" );

		if( !allowResetPassword.allowedReset ){
			setNextEvent( url=event.buildLink( page="forgotten_password" ), persistStruct={
				  message                          = "NEXT_RESET_AFTER_X_MINUTES"
				, nextResetPasswordAllowedXMinutes = allowResetPassword.nextAllowedResetAfterXMinutes
			} );
		}

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

		_tokenValidation( argumentCollection = arguments );

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

		var invalidTokenAction = getSystemSetting( "website_users", "invalid_reset_password_token_action", "default_action" );
		if ( websiteLoginService.resetPassword( token=token, password=pw, allowOldToken=( invalidTokenAction=="allow_non_expired_token" ) ) ) {
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

		_tokenValidation( argumentCollection = arguments );

		var passwordPolicy = passwordPolicyService.getPolicy( "website" );

		if ( Len( Trim( passwordPolicy.message ?: "" ) ) ) {
			prc.policyMessage = renderContent( "richeditor", passwordPolicy.message );
		}

		return renderView( view="/login/resetPassword", presideObject="reset_password", id=event.getCurrentPageId(), args=args );
	}

	private void function _tokenValidation( event, rc, prc, args={} ) {

		rc.token = rc.token ?: "";

		var invalidTokenAction = getSystemSetting( "website_users", "invalid_reset_password_token_action", "default_action" );

		if ( isEmpty( rc.token ) ) {
			setNextEvent( url=event.buildLink( page="forgotten_password" ), persistStruct={
				message = "INVALID_RESET_TOKEN"
			} );
		}

		var latestToken = websiteLoginService.getUserRecordByToken( rc.token );

		if ( !latestToken.recordCount  || latestToken.recordCount && !( isBoolean( latestToken.is_token_valid ?: "" ) && latestToken.is_token_valid ) ) {
			var olderVersionToken = websiteLoginService.getUserRecordByToken( token=rc.token, fromVersionTable=true );
			var persist           = {
				message = "INVALID_RESET_TOKEN"
			};

			switch( invalidTokenAction ){
				case 'newer_token_was_generated':
					if( olderVersionToken.recordCount ){
						if( !isEmpty( olderVersionToken.latest_token_created_date ?: "" ) ){
							persist.latestTokenDate = isDate( olderVersionToken.latest_token_created_date ?: "" ) ? dateFormat( olderVersionToken.latest_token_created_date, 'dd mmm, yyyy' ) & ' ' & timeFormat( olderVersionToken.latest_token_created_date, 'HH:MM:SS' ) : "";
							persist.message         = "NEWER_TOKEN_WAS_GENERATED";
						} else {
							persist.lastPasswordUpdated = isDate( olderVersionToken.last_password_updated ?: "" ) ? dateFormat( olderVersionToken.last_password_updated, 'dd mmm, yyyy' ) & ' ' & timeFormat( olderVersionToken.last_password_updated, 'HH:MM:SS' ) : "";
							persist.message             = "LAST_PASSWORD_UPDATED";
						}
					}
				break;
				case 'allow_non_expired_token':
					if( ( olderVersionToken.is_token_valid ?: false ) ){
						if( isDate( olderVersionToken.last_password_updated ?: "" ) && olderVersionToken.last_password_updated >= olderVersionToken.reset_password_datecreated ){
							persist.lastPasswordUpdated = isDate( olderVersionToken.last_password_updated ?: "" ) ? dateFormat( olderVersionToken.last_password_updated, 'dd mmm, yyyy' ) & ' ' & timeFormat( olderVersionToken.last_password_updated, 'HH:MM:SS' ) : "";
							persist.message             = "LAST_PASSWORD_UPDATED";
						} else {
							persist.message = "";
						}
					}
				break;
			}

			if( !isEmpty( persist.message ?: "" ) ){
				setNextEvent( url=event.buildLink( page="forgotten_password" ), persistStruct=persist );
			}

		}

		return;
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