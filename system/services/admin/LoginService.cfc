/**
 * Service class to provide API methods related to
 * CMS admin login and user sessions. See [[cmspermissioning]]
 * for a full guide to CMS admin users.
 *
 * @presideService
 * @singleton
 * @autodoc
 */
component displayName="Admin login service" {

// CONSTRUCTOR
	/**
	 * @sessionStorage.inject      coldbox:plugin:sessionStorage
	 * @bCryptService.inject       BCryptService
	 * @systemUserList.inject      coldbox:setting:system_users
	 * @userDao.inject             presidecms:object:security_user
	 * @emailService.inject        emailService
	 * @googleAuthenticator.inject googleAuthenticator
	 * @qrCodeGenerator.inject     qrCodeGenerator
	 */
	public any function init(
		  required any    sessionStorage
		, required any    bCryptService
		, required string systemUserList
		, required any    userDao
		, required any    emailService
		, required any    googleAuthenticator
		, required any    qrCodeGenerator
		,          string sessionKey      = "admin_user"
		,          string twoFaSessionKey = "admin_user_authenticated_with_2fa"
	) {
		_setSessionStorage( arguments.sessionStorage );
		_setBCryptService( arguments.bCryptService );
		_setSystemUserList( arguments.systemUserList );
		_setUserDao( arguments.userDao );
		_setSessionKey( arguments.sessionKey );
		_setTwoFaSessionKey( arguments.twoFaSessionKey );
		_setGoogleAuthenticator( arguments.googleAuthenticator );
		_setEmailService( arguments.emailService );
		_setQrCodeGenerator( arguments.qrCodeGenerator )

		return this;
	}

// PUBLIC METHODS
	/**
	 * Attempts CMS admin login with login ID and password. Returns true on success,
	 * false otherwise. See [[cmspermissioning]]
	 * for a full guide to CMS admin users.
	 *
	 * @autodoc
	 * @loginId.hint  User provided login ID / email address
	 * @password.hint User provided password
	 *
	 */
	public boolean function login( required string loginId, required string password ) {
		var usr = _getUserByLoginId( arguments.loginId );
		var success = usr.recordCount and _getBCryptService().checkPw( arguments.password, usr.password );

		if ( success ) {
			_persistUserSession( usr );
			recordLogin();
		}

		return success;
	}

	/**
	 * Validates the logged in user's password
	 *
	 * @autodoc
	 * @password.hint the user provided password
	 */
	public boolean function isPasswordCorrect( required string password ) {
		var userId = getLoggedInUserId();

		if ( !userId.len() ) {
			return false;
		}

		var usr = _getUserDao().selectData( id=userId, selectFields=[ "password" ] );

		return usr.recordCount && _getBCryptService().checkPw( arguments.password, usr.password );
	}

	/**
	 * Logs the currently logged in user session
	 * out of the CMS admin. See [[cmspermissioning]]
	 * for a full guide to CMS admin users.
	 *
	 * @autodoc
	 */
	public void function logout() {
		if ( isLoggedIn() ) {
			recordLogout();
			_destroyUserSession();
		}
	}

	/**
	 * Returns whether or not the current request
	 * is for a user who is logged into the CMS admin.
	 * See [[cmspermissioning]] for a full guide to CMS admin users.
	 *
	 * @autodoc
	 */
	public boolean function isLoggedIn() {
		return _getSessionStorage().exists( name=_getSessionKey() );
	}

	/**
	 * Returns a structure of user details of the
	 * currently logged in CMS admin user.
	 * The structure will contain a key for every property in
	 * the [[presideobject-security_user]] object.
	 * If no user is logged in, an empty structure will be returned.
	 * \n
	 * See [[cmspermissioning]] for a full guide to CMS admin users.
	 *
	 * @autodoc
	 *
	 */
	public struct function getLoggedInUserDetails() {
		if ( !StructKeyExists( request, "__presideCmsAminUserDetails" ) ) {
			var userId = getLoggedInUserId();

			if ( Len( Trim( userId ?: "" ) ) ) {
				var userRecord = _getUserDao().selectData( id=userId );
				if ( userRecord.recordCount ) {
					for( var u in userRecord ) {
						request.__presideCmsAminUserDetails = u; break;  // query row to struct hack
					}

					request.__presideCmsAminUserDetails.delete( "password" );
				} else {
					request.__presideCmsAminUserDetails = {};
				}
			} else {
				request.__presideCmsAminUserDetails = {};
			}
		}

		return request.__presideCmsAminUserDetails;
	}

	/**
	 * Returns the id of the logged in CMS admin user. If no user
	 * is logged in, returns an empty string.
	 * See [[cmspermissioning]] for a full guide to CMS admin users.
	 *
	 * @autodoc
	 *
	 */
	public string function getLoggedInUserId() {
		var userId = _getSessionStorage().getVar( name=_getSessionKey(), default="" );

		return userId ?: "";
	}

	/**
	 * Returns whether or not the logged in user is a "System user".
	 * See [[cmspermissioning]] for a full guide to CMS admin users.
	 *
	 * @autodoc
	 *
	 */
	public boolean function isSystemUser() {
		return isLoggedIn() and ListFindNoCase( _getSystemUserList(), getLoggedInUserDetails().login_id );
	}

	public string function getSystemUserId() {
		var systemUser = ListFirst( _getSystemUserList() );
		var usr        = _getUserDao().selectData(
			  selectFields = [ "id" ]
			, filter       = { login_id = systemUser }
		);

		if ( usr.recordCount ) {
			return usr.id;
		}

		return _getUserDao().insertData( {
			  known_as      = "System administrator"
			, login_id      = systemUser
			, password      = ""
			, email_address = ""
		} );
	}

	public boolean function isUserDatabaseNotConfigured() {
		var user = _getUserDao().selectData( selectFields=[ "login_id", "password" ], maxRows=2 );

		return user.recordCount == 1 && !Len( Trim( user.password ) ) && user.login_id == ListFirst( _getSystemUserList() );
	}

	public boolean function firstTimeUserSetup( required string emailAddress, required string password ) {
		return _getUserDao().updateData( id=getSystemUserId(), data={
			  email_address = arguments.emailAddress
			, password      = _getBCryptService().hashPw( arguments.password )
		} );
	}

	/**
	 * Sends password reset instructions to the supplied user. Returns true if successful, false otherwise.
	 *
	 * @autodoc
	 * @loginId.hint Either the email address or login id of the user
	 */
	public boolean function sendPasswordResetInstructions( required string loginId ) {
		var userRecord = _getUserByLoginId( arguments.loginId );

		if ( userRecord.recordCount ) {
			var tokenInfo = createLoginResetToken( userRecord.id );

			_getEmailService().send(
				  template = "resetCMSPassword"
				, to       = [ userRecord.email_address ]
				, args     = { resetToken = "#tokenInfo.resetToken#-#tokenInfo.resetKey#", expires=tokenInfo.resetExpiry, username=userRecord.known_as }
			);

			return true;
		}

		return false;
	}

	/**
	 * Sends a welcome email to the given user with password reset instructions
	 *
	 * @autodoc
	 * @userId.hint ID of the user to send the welcome email to
	 * @welcomeMessage.hint User supplied welcome message
	 */
	public boolean function sendWelcomeEmail( required string userId, required string createdBy, string welcomeMessage="" ) {
		var userRecord = _getUserDao().selectData( id=arguments.userId );

		if ( userRecord.recordCount ) {
			var tokenInfo = createLoginResetToken( userRecord.id );

			_getEmailService().send(
				  template = "cmsWelcome"
				, to       = [ "#(userRecord.known_as ?: '')# <#(userRecord.email_address ?: '')#>" ]
				, args     = {
					  resetToken     = "#tokenInfo.resetToken#-#tokenInfo.resetKey#"
					, expires        = tokenInfo.resetExpiry
					, username       = userRecord.known_as
					, welcomeMessage = arguments.welcomeMessage
					, createdBy      = arguments.createdBy
					, loginId        = userRecord.login_id
				}
			);

			return true;
		}

		return false;
	}

	/**
	 * Creates a login reset token for a user and return a struct with token details.
	 * Struct keys are: resetToken, resetKey and resetExpiry
	 *
	 * @autodoc
	 * @userId.hint ID of the user to create a reset token for
	 */
	public struct function createLoginResetToken( required string userId ) {
		var resetToken       = _createTemporaryResetToken();
		var resetKey         = _createTemporaryResetKey();
		var hashedResetKey   = _getBCryptService().hashPw( resetKey );
		var resetTokenExpiry = _createTemporaryResetTokenExpiry();

		_getUserDao().updateData( id=arguments.userId, data={
			  reset_password_token        = resetToken
			, reset_password_key          = hashedResetKey
			, reset_password_token_expiry = resetTokenExpiry
		} );

		return {
			  resetToken  = resetToken
			, resetKey    = resetKey
			, resetExpiry = resetTokenExpiry
		};
	}

	/**
	 * Validates a password reset token that has been passed through the URL after
	 * a user has followed 'reset password' link in instructional email.
	 *
	 * @autodoc
	 * @token.hint The token to validate
	 */
	public boolean function validateResetPasswordToken( required string token ) {
		var record = _getUserRecordByPasswordResetToken( arguments.token );

		return record.recordCount == 1;
	}

	/**
	 * Resets a password by looking up the supplied password reset token and encrypting the supplied password
	 *
	 * @autodoc
	 * @token.hint    The temporary reset password token to look the user up with
	 * @password.hint The new password
	 */
	public boolean function resetPassword( required string token, required string password ) {
		var record = _getUserRecordByPasswordResetToken( arguments.token );

		if ( record.recordCount ) {
			var hashedPw = _getBCryptService().hashPw( password );

			return _getUserDao().updateData(
				  id   = record.id
				, data = { password=hashedPw, reset_password_token="", reset_password_key="", reset_password_token_expiry="" }
			);
		}
		return false;
	}

	/**
	 * Sets the last logged in date for the logged in user
	 *
	 * @autodoc
	 */
	public boolean function recordLogin() {
		var userId = getLoggedInUserId();

		return !Len( Trim( userId ) ) ? false : _getUserDao().updateData( id=userId, data={
			last_logged_in = Now()
		} );
	}

	/**
	 * Sets the last logged out date for the logged in user. Note, must be
	 * called before logging the user out
	 *
	 * @autodoc
	 */
	public boolean function recordLogout() {
		var userId = getLoggedInUserId();

		return !Len( Trim( userId ) ) ? false : _getUserDao().updateData( id=userId, data={
			last_logged_out = Now()
		} );
	}

	/**
	 * Records the visit for the currently logged in user
	 * Currently, all this does is to set the last request made datetime value
	 *
	 * @autodoc
	 */
	public boolean function recordVisit() {
		var userId = getLoggedInUserId();

		return !Len( Trim( userId ) ) ? false : _getUserDao().updateData( id=userId, data={
			last_request_made = Now()
		} );
	}


	/**
	 * Returns whether or not two factor authentication is required
	 * for the current user. This is a combination of whether or not
	 * the feature is enabled, whether or not authentication is enabled
	 * for the admin, whether or not authentication is enforced or enabled
	 * by the user and whether or not the user is already authenticated.
	 *
	 * @autodoc
	 * @ipAddress.hint The originating IP address of the request
	 * @userAgent.hint The originating user agent of the request
	 */
	public boolean function twoFactorAuthenticationRequired( required string ipAddress, required string userAgent ) {
		if ( isTwoFactorAuthenticated( argumentCollection=arguments ) ) {
			return false;
		}

		if ( !$isFeatureEnabled( "twoFactorAuthentication" ) ) {
			return false;
		}

		var configuration = $getPresideCategorySettings( "two-factor-auth" );
		var adminEnabled  = IsBoolean( configuration.admin_enabled  ?: "" ) && configuration.admin_enabled;
		var adminEnforced = IsBoolean( configuration.admin_enforced ?: "" ) && configuration.admin_enforced;

		return adminEnabled && ( adminEnforced || isTwoFactorAuthenticationEnabledForUser() );
	}

	/**
	 * Returns whether or not the logged in user
	 * has been authenticated with two factor
	 * authentication.
	 *
	 * @autodoc
	 * @ipAddress.hint The originating IP address of the request
	 * @userAgent.hint The originating user agent of the request
	 */
	public boolean function isTwoFactorAuthenticated( required string ipAddress, required string userAgent ) {
		var authenticated = _getSessionStorage().getVar( name=_getTwoFaSessionKey(), default="" );

		if ( IsBoolean( authenticated ?: "" ) && authenticated ) {
			return true;
		}

		var tfaTrustPeriod = Val( $getPresideSetting( "two-factor-auth", "admin_trust_period", 7 ) );
		if ( !tfaTrustPeriod ) {
			return false;
		}

		var tfaLoginRecord = $getPresideObject( "security_user_two_factor_login_record" ).selectData(
			  selectFields = [ "logged_in_date" ]
			, filter       = {
				  security_user = getLoggedInUserId()
				, ip_address    = arguments.ipAddress
				, user_agent    = arguments.userAgent
			  }
		);

		if ( !tfaLoginRecord.recordCount ) {
			return false;
		}

		if ( DateDiff( 'd', Now(), tfaLoginRecord.logged_in_date ) <= tfaTrustPeriod ) {
			_getSessionStorage().setVar( name=_getTwoFaSessionKey(), value=true );
			return true;
		}

		return false;

	}

	/**
	 * Returns the logged in user's secret two factor
	 * authentication key
	 *
	 * @autodoc
	 *
	 */
	public string function getTwoFactorAuthenticationKey() {
		var details = getLoggedInUserDetails();

		return details.two_step_auth_key ?: "";
	}

	/**
	 * Returns whether or not two factor authentication
	 * has been setup for the logged in user
	 *
	 * @autodoc
	 *
	 */
	public boolean function isTwoFactorAuthenticationSetupForUser() {
		var details      = getLoggedInUserDetails();
		var keyGenerated = Len( Trim( details.two_step_auth_key ?: "" ) );
		var keyUsed      = IsBoolean( details.two_step_auth_key_in_use ?: "" ) && details.two_step_auth_key_in_use;

		return keyGenerated && keyUsed;
	}

	/**
	 * Returns whether or not two factor authentication
	 * is enabled for the admin
	 *
	 * @autodoc
	 *
	 */
	public boolean function isTwoFactorAuthenticationEnabled() {
		var adminEnabled = $getPresideSetting( "two-factor-auth", "admin_enabled" );

		return $isFeatureEnabled( "twoFactorAuthentication" ) && IsBoolean( adminEnabled ) && adminEnabled;
	}

	/**
	 * Returns whether or not two factor authentication
	 * is enabled for the logged in user specifically
	 *
	 * @autodoc
	 *
	 */
	public boolean function isTwoFactorAuthenticationEnabledForUser() {
		var details = getLoggedInUserDetails();

		return IsBoolean( details.two_step_auth_enabled ?: "" ) && details.two_step_auth_enabled;
	}


	/**
	 * Generates, saves and returns a new two factor authentication
	 * key for the logged in user
	 *
	 * @autodoc
	 */
	public string function generateTwoFactorAuthenticationKey() {
		var userId = getLoggedInUserId();

		if ( !Len( Trim( userId ) ) ) {
			return "";
		}

		var userRecord = _getUserDao().selectData( id=userId, selectFields=[ "login_id", "password" ] );
		var key        = _getGoogleAuthenticator().generateKey( password=Hash( SerializeJson( userRecord ) ) );

		_getUserDao().updateData( id=userId, data={
			  two_step_auth_key         = key
			, two_step_auth_key_created = Now()
		} );

		return key;
	}

	/**
	 * Returns base64 encoded image of QR code for the given authentication key
	 *
	 * @audotoc
	 * @key.hint  Private authenticator key
	 * @size.hint Size of the image (pixels)
	 */
	public string function getTwoFactorAuthenticationQrCodeImage( required string key, numeric size=125 ) {
		var userDetails     = getLoggedInUserDetails()
		var applicationName = $getPresideSetting( "two-factor-auth", "admin_app_name" );

		if ( !Len( Trim( applicationName ) ) ) {
			applicationName = "PresideCMS";
		}

		var qrCodeUrl = _getGoogleAuthenticator().getOtpUrl(
			  applicationName = applicationName
			, email           = userDetails.email_address ?: ""
			, key             = arguments.key
		);

		return toBase64( _getQrCodeGenerator().generateQrCode( input=qrCodeUrl, size=arguments.size ) );

	}

	/**
	 * Attempts authentication using a one time secret token
	 * generated by google authenticator app for the currently
	 * logged in user. Returns true on success.
	 *
	 * @autodoc
	 * @token.hint     The user provided one time token (should have been generated by authenticator app)
	 * @ipAddress.hint The IP address of the incoming request
	 * @userAgent.hint The user agent ot the incoming request
	 *
	 */
	public boolean function attemptTwoFactorAuthentication( required string token, required string ipAddress, required string userAgent ) {
		var userId = getLoggedInUserId();
		var key    = getTwoFactorAuthenticationKey();

		if ( !key.len() ) {
			return false;
		}

		var authenticated = _getGoogleAuthenticator().verifyGoogleToken(
			  base32Secret = key
			, userValue    = arguments.token
			, grace        = 1
		);

		if ( authenticated ) {
			_getUserDao().updateData( id=userId, data={
				two_step_auth_key_in_use = true
			} );

			var loginRecordDao = $getPresideObject( "security_user_two_factor_login_record" );
			var updated = loginRecordDao.updateData( filter={
				  security_user = userId
				, ip_address    = arguments.ipAddress
				, user_agent    = arguments.userAgent
			}, data={ logged_in_date=Now() } );

			if ( !updated ) {
				loginRecordDao.insertData({
					  security_user  = userId
					, ip_address     = arguments.ipAddress
					, user_agent     = arguments.userAgent
					, logged_in_date = Now()
				});
			}
		}

		_getSessionStorage().setVar( name=_getTwoFaSessionKey(), value=authenticated );

		return authenticated;
	}

	/**
	 * Enables 2FA for the logged in user
	 *
	 * @autodoc
	 *
	 */
	public void function enableTwoFactorAuthenticationForUser() {
		var userId = getLoggedInUserId();

		if ( userId.len() ) {
			_getUserDao().updateData( id=userId, data={ two_step_auth_enabled=true } );
		}
	}

	/**
	 * Disables 2FA for the logged in user
	 *
	 * @autodoc
	 *
	 */
	public void function disableTwoFactorAuthenticationForUser() {
		var userId = getLoggedInUserId();

		if ( userId.len() ) {
			_getUserDao().updateData( id=userId, data={
				  two_step_auth_enabled     = false
				, two_step_auth_key         = ""
				, two_step_auth_key_created = ""
				, two_step_auth_key_in_use  = ""
			} );
		}
	}

// PRIVATE HELPERS
	private void function _persistUserSession( required query usr ) {
		request.delete( "__presideCmsAminUserDetails" );
		_getSessionStorage().setVar( name=_getSessionKey(), value=arguments.usr.id );
		_preventSessionFixation();
	}

	private void function _destroyUserSession() {
		_getSessionStorage().deleteVar( name=_getSessionKey() );
		_getSessionStorage().deleteVar( name=_getTwoFaSessionKey() );
		_preventSessionFixation();
	}

	private query function _getUserByLoginId( required string loginId ) {
		return _getUserDao().selectData(
			  filter       = "( login_id = :login_id or email_address = :login_id ) and active = '1'"
			, filterParams = { login_id = arguments.loginId }
			, useCache     = false
		);
	}

	private string function _createNewLoginTokenSeries() {
		return _createRandomToken();
	}

	private string function _createNewLoginToken() {
		return _createRandomToken();
	}

	private string function _createTemporaryResetToken() {
		return _createRandomToken();
	}

	private string function _createTemporaryResetKey() {
		return _createRandomToken();
	}

	private string function _createRandomToken() {
		var chars    = ListToArray( Replace( CreateUUId(), "-", "", "all" ), "" );
		var token = "";

		while( chars.len() ){
			var position = RandRange( 1, chars.len(), "SHA1PRNG" );

			if ( RandRange( 1, 2, "SHA1PRNG" ) == 1 ) {
				token &= LCase( chars[ position ] );
			} else {
				token &= chars[ position ];
			}

			chars.deleteAt( position );
		}

		return token;
	}

	private date function _createTemporaryResetTokenExpiry() {
		return DateAdd( "n", 2880, Now() );
	}

	private query function _getUserRecordByPasswordResetToken( required string token ) {
		var t = ListFirst( arguments.token, "-" );
		var k = ListLast( arguments.token, "-" );

		var record = _getUserDao().selectData(
			  selectFields = [ "id", "reset_password_key", "reset_password_token_expiry" ]
			, filter       = { reset_password_token = t }
		);

		if ( !record.recordCount ) {
			return record;
		}

		if ( Now() > record.reset_password_token_expiry || !_getBCryptService().checkPw( k, record.reset_password_key ) ) {
			_getUserDao().updateData(
				  id     = record.id
				, data   = { reset_password_token="", reset_password_key="", reset_password_token_expiry="" }
			);

			return QueryNew('');
		}

		return record;
	}

	private void function _preventSessionFixation() {
		var appSettings = getApplicationSettings();

		if ( ( appSettings.sessionType ?: "cfml" ) != "j2ee" ) {
			SessionRotate();
		}
	}

// GETTERS AND SETTERS
	private any function _getSessionStorage() {
		return _sessionStorage;
	}
	private void function _setSessionStorage( required any sessionStorage ) {
		_sessionStorage = arguments.sessionStorage;
	}

	private any function _getBCryptService() {
		return _bCryptService;
	}
	private void function _setBCryptService( required any bCryptService ) {
		_bCryptService = arguments.bCryptService;
	}

	private string function _getSessionKey() {
		return _sessionKey;
	}
	private void function _setSessionKey( required string sessionKey ) {
		_sessionKey = arguments.sessionKey;
	}

	private string function _getTwoFaSessionKey() {
		return _twoFaSessionKey;
	}
	private void function _setTwoFaSessionKey( required string twoFaSessionKey ) {
		_twoFaSessionKey = arguments.twoFaSessionKey;
	}

	private any function _getUserDao() {
		return _userDao;
	}
	private void function _setUserDao( required any userDao ) {
		_userDao = arguments.userDao;
	}

	private string function _getSystemUserList() {
		return _systemUserList;
	}
	private void function _setSystemUserList( required string systemUserList ) {
		_systemUserList = arguments.systemUserList;
	}

	private any function _getEmailService() {
		return _emailService;
	}
	private void function _setEmailService( required any emailService ) {
		_emailService = arguments.emailService;
	}

	private any function _getGoogleAuthenticator() {
		return _googleAuthenticator;
	}
	private void function _setGoogleAuthenticator( required any googleAuthenticator ) {
		_googleAuthenticator = arguments.googleAuthenticator;
	}

	private any function _getQrCodeGenerator() {
		return _qrCodeGenerator;
	}
	private void function _setQrCodeGenerator( required any qrCodeGenerator ) {
		_qrCodeGenerator = arguments.qrCodeGenerator;
	}

}