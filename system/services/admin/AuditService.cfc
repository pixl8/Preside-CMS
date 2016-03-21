/**
 * Provides logic for interacting with form builder forms
 * @presideservice
 */
component output="false" singleton=true {

// CONSTRUCTOR
	/**
	 * @dao.inject presidecms:object:audit_log
	 */
	public any function init( required any dao ) {
		_setDao( arguments.dao );
		return this;
	}

// PUBLIC METHODS
	public void function log(
		  required any    detail
		, required string source
		, required string action
		, required string type
		, required string instance
		, required string userId
	) output=false {
		_getDao().insertData( {
			  detail     = SerializeJSON( arguments.detail )
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

	public query function getAuditTrailLog(
		  numeric startRow = 1
		, numeric maxRows  = 0
		, struct  filter   = {}
		, array   extraFilters = []
	) {
		var records = _getDao().selectData(
			  selectFields = [ "audit_log.id", "audit_log.type", "audit_log.datecreated", "audit_log.action", "audit_log.detail" , "security_user.email_address", "security_user.known_as","audit_log.user"  ]
			, orderby      = "audit_log.datecreated desc"
			, startRow     = arguments.startRow
			, maxRows      = arguments.maxRows
			, filter       = arguments.filter
			, extraFilters = arguments.extraFilters
		);
		return records;
	}
	/**
	 * Returns the auditTrail record matching the given ID
	 *
	 * @autodoc
	 * @auditLogId.hint The ID of the audit log you wish to get
	 *
	 */
	public query function getAuditLog( required string auditLogId ) {
		return $getPresideObject( "audit_log" ).selectData(
			filter = { id=auditLogId }
		);
	}

	public any function renderLogMessage(  required struct log ) {

		var viewletEvent = "renderers.auditLog.auditLogEntry." & arguments.log.action;
		if ( $getColdbox().viewletExists( viewletEvent ) ) {
			return $getColdbox().renderViewlet(
				  event = viewletEvent
				, args  = arguments.log
			);
		} else {
			return $getColdbox().renderViewlet(
				  event = "renderers.content.auditLogEntry.default"
				, args  = arguments.log
			);
		}
	}

// PRIVATE GETTERS AND SETTERS
	private any function _getDao() output=false {
		return _dao;
	}
	private void function _setDao( required any dao ) output=false {
		_dao = arguments.dao;
	}
}