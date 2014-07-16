component output="false" singleton=true {

// CONSTRUCTOR
	/**
	 * @dao.inject presidecms:object:audit_log
	 */
	public any function init( required any dao ) output=false {
		_setDao( arguments.dao );

		return this;
	}

// PUBLIC METHODS
	public void function log(
		  required string detail
		, required string source
		, required string action
		, required string type
		, required string instance
		, required string userId
	) output=false {
		_getDao().insertData( {
			  detail     = arguments.detail
			, source     = arguments.source
			, action     = arguments.action
			, type       = arguments.type
			, instance   = arguments.instance
			, user       = arguments.userId
			, uri        = cgi.request_url
			, user_ip    = cgi.remote_addr
			, user_agent = cgi.http_user_agent
		} );
	}

// PRIVATE GETTERS AND SETTERS
	private any function _getDao() output=false {
		return _dao;
	}
	private void function _setDao( required any dao ) output=false {
		_dao = arguments.dao;
	}
}