/**
 * Provides logic for interacting Preside's [[auditing|Audit log system]]
 *
 * @singleton
 * @presideservice
 * @autodoc
 */
component displayName="Audit Service" {

// CONSTRUCTOR
	/**
	 * @dao.inject presidecms:object:audit_log
	 */
	public any function init( required any dao ) {
		_setDao( arguments.dao );
		return this;
	}

// PUBLIC METHODS
	/**
	 * Inserts a log entry into the system's audit log. You are most likely
	 * to want to use either `$audit()` or `event.audit()` to proxy to this
	 * method (see [[auditing]] for more details).
	 *
	 * @autodoc
	 * @userId.hint   ID of the admin user who performed the action
	 * @action.hint   Key of the action performed, e.g. datamanager_edit_record
	 * @type.hint     Type of action performed, used for grouping audit logs, e.g. datamanager
	 * @recordId.hint ID of the entity that was acted upon. For example, the ID of a record that was edited
	 * @detail.hint   A struct containing data that will be useful when rendering the audit log entry. For example, a list of fields that were changed in an edit process
	 *
	 */
	public void function log(
		  required string userId
		, required string action
		, required string type
		,          string recordId = ""
		,          any    detail   = {}
	) {
		if ( Len( Trim( arguments.userId ) ) ) {
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
	}

	public query function getTrail(
		  numeric page     = 1
		, numeric pageSize = 10
		, string  dateFrom = ""
		, string  dateTo   = ""
		, string  user     = ""
		, string  action   = ""
		, string  type     = ""
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

		if ( Len( Trim( arguments.type ) ) ) {
			filter &= filterDelim & "type = :type";
			filterDelim = " and ";
			params.type = arguments.type;
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

	/**
	 * Renders the given log (a structure of the log detail). See [[auditing]] for
	 * more details on providing custom renderers for log entries.
	 *
	 * @autodoc
	 * @log.hint A struct representing the log. Contains all keys found in the [[presideobject-audit_log]] object with the detail key deserialized to a meaninful datatype
	 */
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

	public array function getLoggedTypes() {
		var types = $getPresideObject( "audit_log" ).selectData(
			  selectFields = [ "distinct type" ]
		);

		return ValueArray( types.type );
	}

// PRIVATE GETTERS AND SETTERS
	private any function _getDao() {
		return _dao;
	}
	private void function _setDao( required any dao ) {
		_dao = arguments.dao;
	}
}