/**
 * The website user manager object provides methods for interacting with the front end users of your sites.
 */
component output=false autodoc=true displayName="Preside Object Service" {

// constructor
	/**
	 * @sessionService.inject sessionService
	 * @userDao.inject        presidecms:object:website_user
	 * @bcryptService.inject  bcryptService
	 */
	public any function init( required any sessionService, required any userDao, required any bcryptService ) output=false {
		_setSessionService( arguments.sessionService );
		_setUserDao( arguments.userDao );
		_setBCryptService( arguments.bcryptService );
		_setSessionKey( "website_user" );

		return this;
	}

// public api methods

	/**
	 * Logs the currently logged in user out of their session
	 *
	 */
	public void function logout() output=false {
		_getSessionService().deleteVar( name=_getSessionKey() );
	}

	/**
	 * Logs the user in by matching the passed login id against either the login id or email address
	 * fields and running a bcrypt password check to verify the security credentials. Returns true on success, false otherwise.
	 *
	 * @loginId.hint Either the login id or email address of the user to login
	 * @password.hint The password that the user has entered during login
	 *
	 */
	public boolean function login( required string loginId, required string password ) output=false {
		if ( !isLoggedIn() ) {
			var userRecord = getUserByLoginId( arguments.loginId );

			if ( userRecord.recordCount && validatePassword( arguments.password, userRecord.password ) ) {
				setUserSession( {
					  id            = userRecord.id
					, login_id      = userRecord.login_id
					, email_address = userRecord.email_address
					, display_name  = userRecord.display_name
				} );

				return true;
			}
		}

		return false;
	}

	/**
	 * Returns whether or not the user making the current request is logged in
	 * to the system.
	 */
	public boolean function isLoggedIn() output=false autodoc=true {
		return _getSessionService().exists( name=_getSessionKey() );;
	}

	/**
	 * Returns the structure of user details belonging to the currently logged in user.
	 * If no user is logged in, an empty structure will be returned.
	 */
	public struct function getLoggedInUserDetails() output=false autodoc=true {
		var userDetails = _getSessionService().getVar( name=_getSessionKey(), default={} );

		return IsStruct( userDetails ) ? userDetails : {};
	}

	/**
	 * Returns the id of the currently logged in user, or an empty string if no user is logged in
	 */
	public string function getLoggedInUserId() output=false autodoc=true {
		var userDetails = getLoggedInUserDetails();

		return userDetails.id ?: "";
	}

	/**
	 * Returns a user record that matches the given login id against either the
	 * login_id field or the email_address field.
	 *
	 * @loginId.hint The login id / email address with which to query the user database
	 */
	public query function getUserByLoginId( required string loginId ) output=false autodoc=true {
		return _getUserDao().selectData(
			  selectFields = [ "id", "login_id", "email_address", "display_name", "password" ]
			, filter       = "( login_id = :login_id or email_address = :login_id ) and active = 1"
			, filterParams = { login_id = arguments.loginId }
			, useCache     = false
		);
	}

	/**
	 * Returns true if the plain text password matches the given hashed password
	 *
	 * @plainText.hint The password provided by the usr
	 * @hashed.text The password stored against the user record
	 */
	public boolean function validatePassword( required string plainText, required string hashed ) output=false {
		return _getBCryptService().checkPw( plainText=arguments.plainText, hashed=arguments.hashed );
	}

	/**
	 * Sets the user's session data
	 *
	 * @data.hint The data to store in the user's session
	 */
	public void function setUserSession( required struct data ) output=false {
		_getSessionService().setVar( name=_getSessionKey(), value=arguments.data );
	}

// private accessors
	private any function _getSessionService() output=false {
		return _sessionService;
	}
	private void function _setSessionService( required any sessionService ) output=false {
		_sessionService = arguments.sessionService;
	}

	private any function _getUserDao() output=false {
		return _userDao;
	}
	private void function _setUserDao( required any userDao ) output=false {
		_userDao = arguments.userDao;
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
}