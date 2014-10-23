component output=false extends="coldbox.system.logging.AbstractAppender" {

// CONSTRUCTOR
	public any function init( required string name, struct properties = {}, string layout = "", numeric levelMin = 0, numeric levelMax = 4 ) output=false {
		return super.init( argumentCollection = arguments );
	}

// PUBLIC API METHODS
	public void function logMessage( required any logEvent ) output=false {
		var e = arguments.logEvent;

		_getLogDao().insertData({
			  severity      = super.severityToString( e.getSeverity() )
			, category      = e.getCategory()
			, message       = e.getMessage()
			, extra_info    = e.getExtraInfoAsString()
			, admin_user_id = _getAdminLoginService().getLoggedInUserId()
			, web_user_id   = _getWebsiteLoginService().getLoggedInUserId()
		});
	}

// PRIVATE
	private any function _getLogDao() output=false {
		if ( !StructKeyExists( variables, "_logDao" ) ) {
			_logDao = getColdbox().getWireBox().getInstance( dsl="presidecms:object:log_entry" );
		}

		return _logDao;
	}

	private any function _getAdminLoginService() output=false {
		if ( !StructKeyExists( variables, "_adminLoginService" ) ) {
			_adminLoginService = getColdbox().getWireBox().getInstance( name="loginService" );
		}

		return _adminLoginService;
	}

	private any function _getWebsiteLoginService() output=false {
		if ( !StructKeyExists( variables, "_websiteLoginService" ) ) {
			_websiteLoginService = getColdbox().getWireBox().getInstance( name="websiteLoginService" );
		}

		return _websiteLoginService;
	}

}