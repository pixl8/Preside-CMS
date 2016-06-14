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
		, required string action
		, required string type
		,          string recordId = ""
		,          any    detail   = {}
	) {
		_getDao().insertData( {
			  detail     = SerializeJSON( arguments.detail )
			, action     = arguments.action
			, type       = arguments.type
			, user       = arguments.userId
			, record_id  = arguments.recordId
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
		, string  recordId = ""
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

		if ( Len( Trim( arguments.recordId ) ) ) {
			filter &= filterDelim & "record_id = :record_id";
			filterDelim = " and ";
			params.record_id = arguments.recordId;
		}

		if ( !Len( Trim( filter ) ) ) {
			filter = {};
		}

		return _getDao().selectData(
			  filter       = filter
			, filterParams = params
			, orderby      = "audit_log.datecreated desc"
			, maxRows      = arguments.pageSize
			, startRow     = ( ( arguments.page - 1 ) * arguments.pageSize ) + 1
			, selectFields = [
				  "audit_log.id"
				, "audit_log.type"
				, "audit_log.datecreated"
				, "audit_log.action"
				, "audit_log.detail"
				, "audit_log.record_id"
				, "audit_log.uri"
				, "audit_log.user_ip"
				, "audit_log.user_agent"
				, "security_user.email_address"
				, "security_user.known_as"
				, "audit_log.user"
			 ]
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
		return $renderContent(
			  renderer = "auditLogEntry"
			, data     = arguments.log
			, context  = [ arguments.log.action, arguments.log.type ]
		);
	}

	public query function getLoggedActions() {
		return $getPresideObject( "audit_log" ).selectData(
			  selectFields = [ "distinct action", "type" ]
		);
	}

// PRIVATE GETTERS AND SETTERS
	private any function _getDao() {
		return _dao;
	}
	private void function _setDao( required any dao ) {
		_dao = arguments.dao;
	}
}