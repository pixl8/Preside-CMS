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
		  required string userId
		, required string source
		, required string action
		, required string type
		,          any    detail = {}
	) {
		_getDao().insertData( {
			  detail     = SerializeJSON( arguments.detail )
			, source     = arguments.source
			, action     = arguments.action
			, type       = arguments.type
			, user       = arguments.userId
			, uri        = cgi.request_url
			, user_ip    = cgi.remote_addr
			, user_agent = cgi.http_user_agent
		} );
	}

	public query function getTrail(
		  numeric page     = 1
		, numeric pageSize = 10
		, string  dateFrom = ""
		, string  dateTo   = ""
		, string  user     = ""
		, string  action   = ""
	) {
		var filter = "";
		var filterDelim = "";
		var params = {};

		if ( IsDate( arguments.dateFrom ) ) {
			filter = "audit_log.datecreated >= :datefrom";
			filterDelim = " and ";
			params.datefrom = { value=arguments.dateFrom, type="cf_sql_date" }
		}

		if ( IsDate( arguments.dateTo ) ) {
			filter &= filterDelim & "audit_log.datecreated <= :dateTo";
			filterDelim = " and ";
			params.dateTo = { value=arguments.dateTo, type="cf_sql_date" }
		}

		if ( Len( Trim( arguments.user ) ) ) {
			filter &= filterDelim & "user = :user";
			filterDelim = " and ";
			params.user = arguments.user;
		}

		if ( Len( Trim( arguments.action ) ) ) {
			filter &= filterDelim & "action = :action";
			filterDelim = " and ";
			params.action = arguments.action;
		}

		if ( !Len( Trim( filter ) ) ) {
			filter = {};
		}

		return _getDao().selectData(
			  selectFields = [ "audit_log.id", "audit_log.type", "audit_log.datecreated", "audit_log.action", "audit_log.detail" , "security_user.email_address", "security_user.known_as","audit_log.user"  ]
			, orderby      = "audit_log.datecreated desc"
			, filter       = filter
			, filterParams = params
			, startRow     = ( ( arguments.page - 1 ) * arguments.pageSize ) + 1
			, maxRows      = arguments.pageSize
		);
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

	public array function getLoggedActions() {
		var records = $getPresideObject( "audit_log" ).selectData(
			  selectFields = [ "distinct action" ]
		);

		return ValueArray( records.action );
	}

// PRIVATE GETTERS AND SETTERS
	private any function _getDao() {
		return _dao;
	}
	private void function _setDao( required any dao ) {
		_dao = arguments.dao;
	}
}