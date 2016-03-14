/**
 * Provides logic for interacting with form builder forms
 * @presideservice
 */
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

	public query function getAuditLog(
		  numeric startRow = 1
		, numeric maxRows  = 0
		) output=false {
		var records = _getDao().selectData(
				selectFields = [ "audit_log.id", "audit_log.type", "audit_log.datecreated", "audit_log.action", "security_user.email_address", "security_user.known_as"  ]
				, orderby    = "audit_log.datecreated desc"
				, startRow   = arguments.startRow
				, maxRows    = arguments.maxRows
			);

		return records;
	}

	/**
	 * Returns the auditTrail record matching the given ID
	 *
	 * @autodoc
	 * @auditTrailId.hint The ID of the auditTrail you wish to get
	 *
	 */
	public query function getAuditTrail( required string auditTrailId ) {
		return $getPresideObject( "audit_log" ).selectData(
			filter = { id=auditTrailId }
		);
	}

// PRIVATE GETTERS AND SETTERS
	private any function _getDao() output=false {
		return _dao;
	}
	private void function _setDao( required any dao ) output=false {
		_dao = arguments.dao;
	}
}