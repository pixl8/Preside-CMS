component output="false" singleton=true {

// CONSTRUCTOR
	/**
	 * @sessionService.inject SessionService
	 * @bCryptService.inject  BCryptService
	 * @systemUserList.inject coldbox:setting:system_users
	 * @userDao.inject        presidecms:object:security_user
	 */
	public any function init(
		  required any    sessionService
		, required any    bCryptService
		, required string systemUserList
		, required any    userDao
		,          string sessionKey = "admin_user"
	) output=false {
		_setSessionService( arguments.sessionService );
		_setBCryptService( arguments.bCryptService );
		_setSystemUserList( arguments.systemUserList );
		_setUserDao( arguments.userDao );
		_setSessionKey( arguments.sessionKey );

		return this;
	}

// PUBLIC METHODS
	public boolean function login( required string loginId, required string password ) output=false {
		var usr = _getUserDao().selectData(
			  filter       = "( login_id = :login_id or email_address = :login_id ) and active = 1"
			, filterParams = { login_id = arguments.loginId }
			, useCache     = false
		);
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
			  label         = "System administrator"
			, login_id      = systemUser
			, password      = _getBCryptService().hashPw( "password" )
			, email_address = ""
		} );
	}

// PRIVATE HELPERS
	private void function _persistUserSession( required query usr ) output=false {
		var persistData = {
			  loginId      = arguments.usr.login_id
			, knownAs      = arguments.usr.label
			, emailAddress = arguments.usr.email_address
			, userId       = arguments.usr.id
		};

		_getSessionService().setVar( name=_getSessionKey(), value=persistData );
	}

	private void function _destroyUserSession() output=false {
		_getSessionService().deleteVar( name=_getSessionKey() );
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

}