component extends="preside.system.base.AdminHandler" output=false {

	property name="loginService"      inject="loginService";
	property name="sessionService"    inject="sessionService";
	property name="adminDefaultEvent" inject="coldbox:setting:adminDefaultEvent";
	property name="messageBox"        inject="coldbox:plugin:messageBox";

	public void function preHandler( event, action, eventArguments ) output=false {
		super.preHandler( argumentCollection = arguments );

		event.setLayout( 'adminLogin' );
	}

	public void function index( event, rc, prc ) output=false {
		if ( event.isAdminUser() ){
			setNextEvent( url=event.buildAdminLink( linkto=adminDefaultEvent ) );
		}
	}

	public void function login( event, rc, prc ) output=false {
		var user         = "";
		var postLoginUrl = event.getValue( name="postLoginUrl", defaultValue="" );
		var unsavedData  = sessionService.getVar( "_unsavedFormData", {} );
		var loggedIn     = loginService.logIn(
			  loginId  = event.getValue( name="loginId" , defaultValue="" )
			, password = event.getValue( name="password", defaultValue="" )
		);

		if ( loggedIn ) {
			user = event.getAdminUserDetails();
			event.audit(
				  detail   = "[#user.knownAs#] has logged in"
				, source   = "login"
				, action   = "login_success"
				, type     = "user"
				, instance = user.userId
			);

			if ( Len( Trim( postLoginUrl ) ) ) {
				sessionService.deleteVar( "_unsavedFormData", {} );
				setNextEvent( url=_cleanPostLoginUrl( postLoginUrl ), persistStruct=unsavedData );
			} else {
				setNextEvent( url=event.buildAdminLink( linkto=adminDefaultEvent ) );
			}
		} else {
			setNextEvent( url=event.buildAdminLink( linkto="login", persist="postLoginUrl" ) );
		}
	}

	public void function logout( event, rc, prc ) output=false {
		var user        = "";

		if ( event.isAdminUser() ) {
			user = event.getAdminUserDetails();

			event.audit(
				  detail   = "[#user.knownAs#] has logged out"
				, source   = "logout"
				, action   = "logout_success"
				, type     = "user"
				, instance = user.userId
			);

			loginService.logout();
		}

		if ( ( rc.redirect ?: "" ) == "referer" ) {
			setNextEvent( url=cgi.http_referer );
		}

		setNextEvent( url=event.buildAdminLink( linkto="login" ) );
	}

	public void function forgottenPassword( event, rc, prc ) output=false {
		if ( event.isAdminUser() ){
			setNextEvent( url=event.buildAdminLink( linkto=adminDefaultEvent ) );
		}

		event.setView( "/admin/login/forgottenPassword" );
	}

	public void function sendResetInstructions( event, rc, prc ) output=false {
		if ( loginService.sendPasswordResetInstructions( rc.loginId ?: "" ) ) {
			setNextEvent( url=event.buildAdminLink( linkTo="login.forgottenPassword" ), persistStruct={
				message = "PASSWORD_RESET_INSTRUCTIONS_SENT"
			} );
		}

		setNextEvent( url=event.buildAdminLink( linkTo="login.forgottenPassword" ), persistStruct={
			message = "LOGINID_NOT_FOUND"
		} );
	}

	public void function resetPassword( event, rc, prc ) output=false {
		if ( event.isAdminUser() ){
			setNextEvent( url=event.buildAdminLink( linkto=adminDefaultEvent ) );
		}

		if ( !loginService.validateResetPasswordToken( rc.token ?: "" ) ) {
			setNextEvent( url=event.buildAdminLink( linkTo="login.forgottenPassword" ), persistStruct={
				message = "INVALID_RESET_TOKEN"
			} );
		}

		event.setView( "/admin/login/resetPassword" );
	}

	public void function resetPasswordAction( event, rc, prc ) output=false {
		var pw           = rc.password             ?: "";
		var confirmation = rc.passwordConfirmation ?: "";
		var token        = rc.token                ?: "";

		if ( !loginService.validateResetPasswordToken( rc.token ?: "" ) ) {
			setNextEvent( url=event.buildAdminLink( linkTo="login.forgottenPassword" ), persistStruct={
				message = "INVALID_RESET_TOKEN"
			} );
		}

		if ( !Len( Trim( pw ) ) ) {
			setNextEvent( url=event.buildAdminLink( linkTo="login.resetPassword" ), persistStruct={
				  message = "EMPTY_PASSWORD"
				, token   = token
			} );
		}

		if ( pw != confirmation ) {
			setNextEvent( url=event.buildAdminLink( linkTo="login.resetPassword" ), persistStruct={
				  message = "PASSWORDS_DO_NOT_MATCH"
				, token   = token
			} );
		}

		if ( loginService.resetPassword( token=token, password=pw ) ) {
			setNextEvent( url=event.buildAdminLink( linkTo="login" ), persistStruct={
				message = "PASSWORD_RESET"
			} );
		}

		setNextEvent( url=event.buildAdminLink( linkTo="login.resetPassword" ), persistStruct={
			  message = "UNKNOWN_ERROR"
			, token   = token
		} );

	}

// private helpers
	private string function _cleanPostLoginUrl( required string postLoginUrl ) {
		var cleaned = Trim( arguments.postLoginUrl );

		cleaned = ReReplace( cleaned, "^(https?://.*?)//", "\1/" );

		return cleaned;
	}
}