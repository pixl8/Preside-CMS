/**
 * The website user manager object provides methods for interacting with the front end users of your sites. In particular, it deals with login and user lookups.
 * \n
 * See also: :doc:`/reference/presideobjects/website_user`
 */
component output=false autodoc=true displayName="Website user service" {

// constructor
	/**
	 * @sessionService.inject    sessionService
	 * @cookieService.inject     cookieService
	 * @userDao.inject           presidecms:object:website_user
	 * @userLoginTokenDao.inject presidecms:object:website_user_login_token
	 * @bcryptService.inject     bcryptService
	 */
	public any function init( required any sessionService, required any cookieService, required any userDao, required any userLoginTokenDao, required any bcryptService ) output=false {
		_setSessionService( arguments.sessionService );
		_setCookieService( arguments.cookieService );
		_setUserDao( arguments.userDao );
		_setUserLoginTokenDao( arguments.userLoginTokenDao );
		_setBCryptService( arguments.bcryptService );
		_setSessionKey( "website_user" );
		_setRememberMeCookieKey( "_presidecms-site-persist" );

		return this;
	}

// public api methods

	/**
	 * Logs the user in by matching the passed login id against either the login id or email address
	 * fields and running a bcrypt password check to verify the security credentials. Returns true on success, false otherwise.
	 *
	 * @loginId.hint              Either the login id or email address of the user to login
	 * @password.hint             The password that the user has entered during login
	 * @rememberLogin.hint        Whether or not to set a "remember me" cookie
	 * @rememberExpiryInDays.hint When setting a remember me cookie, how long (in days) before the cookie should expire
	 *
	 */
	public boolean function login( required string loginId, required string password, boolean rememberLogin=false, rememberExpiryInDays=90 ) output=false {
		if ( !isLoggedIn() ) {
			var userRecord = _getUserByLoginId( arguments.loginId );

			if ( userRecord.recordCount && _validatePassword( arguments.password, userRecord.password ) ) {
				_setUserSession( {
					  id            = userRecord.id
					, login_id      = userRecord.login_id
					, email_address = userRecord.email_address
					, display_name  = userRecord.display_name
				} );

				if ( arguments.rememberLogin ) {
					_setRememberMeCookie( userId=userRecord.id, loginId=userRecord.login_id, expiry=arguments.rememberExpiryInDays );
				}

				return true;
			}
		}

		return false;
	}

	/**
	 * Logs the currently logged in user out of their session
	 *
	 */
	public void function logout() output=false {
		_getSessionService().deleteVar( name=_getSessionKey() );
		if ( _getCookieService().exists( _getRememberMeCookieKey() ) ) {
			var cookieValue = _readRememberMeCookie();
			_deleteRememberMeCookie();

			if ( Len( cookieValue.series ?: "" ) ) {
				_getUserLoginTokenDao().deleteData( filter={ series = cookieValue.series } );
			}
		}
	}

	/**
	 * Returns whether or not the user making the current request is logged in
	 * to the system.
	 *
	 * @securityAlertCallback.hint A function that will be invoked should their be a security alert during auto login checking. Use this to alert the user that their login may have been compromised.
	 */
	public boolean function isLoggedIn( function securityAlertCallback=function(){} ) output=false autodoc=true {
		var userSessionExists = _getSessionService().exists( name=_getSessionKey() );

		return userSessionExists || _autoLogin( argumentCollection = arguments );
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

// private helpers
	private query function _getUserByLoginId( required string loginId ) output=false autodoc=true {
		return _getUserDao().selectData(
			  selectFields = [ "id", "login_id", "email_address", "display_name", "password" ]
			, filter       = "( login_id = :login_id or email_address = :login_id ) and active = 1"
			, filterParams = { login_id = arguments.loginId }
			, useCache     = false
		);
	}

	private boolean function _validatePassword( required string plainText, required string hashed ) output=false autodoc=true {
		return _getBCryptService().checkPw( plainText=arguments.plainText, hashed=arguments.hashed );
	}

	private void function _setUserSession( required struct data ) output=false {
		_getSessionService().setVar( name=_getSessionKey(), value=arguments.data );
	}

	private void function _setRememberMeCookie( required string userId, required string loginId, required string expiry ) output=false {
		var cookieValue = {
			  loginId = arguments.loginId
			, expiry  = arguments.expiry
			, series  = _createNewLoginTokenSeries()
			, token   = _createNewLoginToken()
		};

		_getUserLoginTokenDao().insertData( data={
			  user   = arguments.userId
			, series = cookieValue.series
			, token  = _getBCryptService().hashPw( cookieValue.token )
		} );

		_getCookieService().setVar(
			  name     = _getRememberMeCookieKey()
			, value    = cookieValue
			, expires  = arguments.expiry
			, httpOnly = true
		);
	}

	private void function _deleteRememberMeCookie() output=false {
		_getCookieService().deleteVar( _getRememberMeCookieKey() );
	}

	private struct function _readRememberMeCookie() output=false {
		var cookieValue = _getCookieService().getVar( _getRememberMeCookieKey(), {} );

		if ( IsStruct( cookieValue ) ) {
			var keys = cookieValue.keyArray()
			keys.sort( "textNoCase" );

			if ( keys.toList() == "expiry,loginId,series,token" ) {
				return cookieValue;
			}
		}

		return {};
	}

	private boolean function _autoLogin( required function securityAlertCallback ) output=false {
		if ( StructKeyExists( request, "_presideWebsiteAutoLoginResult" ) ) {
			return request._presideWebsiteAutoLoginResult;
		}

		if ( _getCookieService().exists( _getRememberMeCookieKey() ) ) {
			var cookieValue = _readRememberMeCookie();
			var tokenRecord = _getUserRecordFromCookie( cookieValue, securityAlertCallback );

			if ( tokenRecord.recordCount ) {
				_setUserSession( {
					  id            = tokenRecord.user
					, login_id      = tokenRecord.login_id
					, email_address = tokenRecord.email_address
					, display_name  = tokenRecord.display_name
				} );

				_recycleLoginToken( tokenRecord.id, cookieValue );

				request._presideWebsiteAutoLoginResult = true;
				return true;
			}

			_deleteRememberMeCookie();
		}

		request._presideWebsiteAutoLoginResult = false;
		return false;

	}

	private query function _getUserRecordFromCookie( required struct cookieValue, required function securityAlertCallback ) output=false {
		if ( StructCount( arguments.cookieValue ) ) {
			var tokenRecord = _getUserLoginTokenDao().selectData(
				  selectFields = [ "website_user_login_token.id", "website_user_login_token.token", "website_user_login_token.user", "website_user.login_id", "website_user.email_address", "website_user.display_name" ]
				, filter       = { series = arguments.cookieValue.series }
			);

			if ( tokenRecord.recordCount && tokenRecord.login_id == arguments.cookieValue.loginId ) {
				if ( _getBCryptService().checkPw( arguments.cookieValue.token, tokenRecord.token ) ) {
					return tokenRecord;
				}

				_getUserLoginTokenDao().deleteData( id=tokenRecord.id );
				securityAlertCallback();
			}
		}

		return QueryNew('');
	}

	private void function _recycleLoginToken( required string tokenId, required struct cookieValue ) output=false {
		arguments.cookieValue.token = _createNewLoginToken();

		_getUserLoginTokenDao().updateData(
			  id   = arguments.tokenId
			, data = { token = _getBCryptService().hashPw( arguments.cookieValue.token )
		} );

		_getCookieService().setVar(
			  name     = _getRememberMeCookieKey()
			, value    = arguments.cookieValue
			, expires  = arguments.cookieValue.expiry
			, httpOnly = true
		);
	}

	private string function _createNewLoginTokenSeries() output=false {
		return CreateUUId();
	}

	private string function _createNewLoginToken() output=false {
		return CreateUUId();
	}


// private accessors
	private any function _getSessionService() output=false {
		return _sessionService;
	}
	private void function _setSessionService( required any sessionService ) output=false {
		_sessionService = arguments.sessionService;
	}

	private any function _getCookieService() output=false {
		return _cookieService;
	}
	private void function _setCookieService( required any cookieService ) output=false {
		_cookieService = arguments.cookieService;
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

	private string function _getRememberMeCookieKey() output=false {
		return _rememberMeCookieKey;
	}
	private void function _setRememberMeCookieKey( required string rememberMeCookieKey ) output=false {
		_rememberMeCookieKey = arguments.rememberMeCookieKey;
	}

	private any function _getUserLoginTokenDao() output=false {
		return _userLoginTokenDao;
	}
	private void function _setUserLoginTokenDao( required any userLoginTokenDao ) output=false {
		_userLoginTokenDao = arguments.userLoginTokenDao;
	}
}