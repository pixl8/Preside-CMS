component output="false" singleton=true {

// CONSTRUCTOR
	/**
	 * @sessionService.inject SessionService
	 * @bCryptService.inject  BCryptService
	 * @systemUserList.inject coldbox:setting:system_users
	 * @userDao.inject        presidecms:object:security_user
	 * @emailService.inject   emailService
	 */
	public any function init(
		  required any    sessionService
		, required any    bCryptService
		, required string systemUserList
		, required any    userDao
		, required any    emailService
		,          string sessionKey = "admin_user"
	) output=false {
		_setSessionService( arguments.sessionService );
		_setBCryptService( arguments.bCryptService );
		_setSystemUserList( arguments.systemUserList );
		_setUserDao( arguments.userDao );
		_setSessionKey( arguments.sessionKey );
		_setEmailService( arguments.emailService );

		return this;
	}

// PUBLIC METHODS
	public boolean function login( required string loginId, required string password ) output=false {
		var usr = _getUserByLoginId( arguments.loginId );
		var success = usr.recordCount and _getBCryptService().checkPw( arguments.password, usr.password );

		if ( success ) {
			_persistUserSession( usr );
		}

		return success;
	}

	public void function logout() output=false {
		if ( isLoggedIn() ) {
			_destroyUserSession();
		}
	}

	public boolean function isLoggedIn() output=false {
		return _getSessionService().exists( name=_getSessionKey() );
	}

	public struct function getLoggedInUserDetails() output=false {
		return _getSessionService().getVar( name=_getSessionKey(), default={} );
	}

	public string function getLoggedInUserId() output=false {
		return getLoggedInUserDetails().userId;
	}

	public boolean function isSystemUser() output=false {
		return isLoggedIn() and ListFindNoCase( _getSystemUserList(), getLoggedInUserDetails().loginId );
	}

	public string function getSystemUserId() output=false {
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
			, password      = _getBCryptService().hashPw( "password" )
			, email_address = ""
		} );
	}

	/**
	 * Sends password reset instructions to the supplied user. Returns true if successful, false otherwise.
	 *
	 * @loginId.hint Either the email address or login id of the user
	 */
	public boolean function sendPasswordResetInstructions( required string loginId ) output=false autodoc=true {
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
	 * @userId.hint ID of the user to send the welcome email to
	 * @welcomeMessage.hint User supplied welcome message
	 */
	public boolean function sendWelcomeEmail( required string userId, required string createdBy, string welcomeMessage="" ) output=false {
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
	 * @userId.hint ID of the user to create a reset token for
	 */
	public struct function createLoginResetToken( required string userId ) output=false {
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
	 * @token.hint The token to validate
	 */
	public boolean function validateResetPasswordToken( required string token ) output=false {
		var record = _getUserRecordByPasswordResetToken( arguments.token );

		return record.recordCount == 1;
	}

	/**
	 * Resets a password by looking up the supplied password reset token and encrypting the supplied password
	 *
	 * @token.hint    The temporary reset password token to look the user up with
	 * @password.hint The new password
	 */
	public boolean function resetPassword( required string token, required string password ) output=false {
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

// PRIVATE HELPERS
	private void function _persistUserSession( required query usr ) output=false {
		var persistData = {
			  loginId      = arguments.usr.login_id
			, knownAs      = arguments.usr.known_as
			, emailAddress = arguments.usr.email_address
			, userId       = arguments.usr.id
		};

		_getSessionService().setVar( name=_getSessionKey(), value=persistData );
	}

	private void function _destroyUserSession() output=false {
		_getSessionService().deleteVar( name=_getSessionKey() );
	}

	private query function _getUserByLoginId( required string loginId ) output=false {
		return _getUserDao().selectData(
			  filter       = "( login_id = :login_id or email_address = :login_id ) and active = 1"
			, filterParams = { login_id = arguments.loginId }
			, useCache     = false
		);
	}

	private string function _createNewLoginTokenSeries() output=false {
		return _createRandomToken();
	}

	private string function _createNewLoginToken() output=false {
		return _createRandomToken();
	}

	private string function _createTemporaryResetToken() output=false {
		return _createRandomToken();
	}

	private string function _createTemporaryResetKey() output=false {
		return _createRandomToken();
	}

	private string function _createRandomToken() output=false {
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

	private date function _createTemporaryResetTokenExpiry() output=false {
		return DateAdd( "n", 60, Now() );
	}

	private query function _getUserRecordByPasswordResetToken( required string token ) output=false {
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

// GETTERS AND SETTERS
	private any function _getSessionService() output=false {
		return _sessionService;
	}
	private void function _setSessionService( required any sessionService ) output=false {
		_sessionService = arguments.sessionService;
	}

	private any function _getBCryptService() output=false {
		return _bCryptService;
	}
	private void function _setBCryptService( required any bCryptService ) output=false {
		_bCryptService = arguments.bCryptService;
	}

	private string function _getSessionKey() output=false {
		return _sessionKey;
	}
	private void function _setSessionKey( required string sessionKey ) output=false {
		_sessionKey = arguments.sessionKey;
	}

	private any function _getUserDao() output=false {
		return _userDao;
	}
	private void function _setUserDao( required any userDao ) output=false {
		_userDao = arguments.userDao;
	}

	private string function _getSystemUserList() output=false {
		return _systemUserList;
	}
	private void function _setSystemUserList( required string systemUserList ) output=false {
		_systemUserList = arguments.systemUserList;
	}

	private any function _getEmailService() output=false {
		return _emailService;
	}
	private void function _setEmailService( required any emailService ) output=false {
		_emailService = arguments.emailService;
	}

}