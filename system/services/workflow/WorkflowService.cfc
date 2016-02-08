/**
 * This will eventually be a proper State Machine system (hopfully)
 * For now, just a simple front to a datastore for storing state
 * with a status and owner.
 *
 * @singleton
 */
component {

// CONSTRUCTOR
	/**
	 * @stateDao.inject      presidecms:object:workflow_state
	 * @cookieService.inject cookieService
	 *
	 */
	public any function init( required any stateDao, required any cookieService ) {
		_setStateDao( arguments.stateDao );
		_setCookieService( arguments.cookieService );
		_setCookieKey( "presideworkflowsession" );

		return this;
	}

// PUBLIC API METHODS
	public string function saveState(
		  required struct state
		, required string status
		,          string workflow   = ""
		,          string reference  = ""
		,          string owner      = _getCookieBasedOwner()
		,          string id         = _getRecordIdByWorkflowNameReferenceAndOwner( arguments.workflow, arguments.reference, arguments.owner )
		,          date   expires

	) {
		var serializedState = SerializeJson( arguments.state );

		if ( Len( Trim( arguments.id ) ) ) {
			_getStateDao().updateData(
				  id   = arguments.id
				, data = { state=serializedState, status=arguments.status, expires=arguments.expires ?: "" }
			);

			return arguments.id;
		}

		return _getStateDao().insertData({
			  state     = serializedState
			, status    = arguments.status
			, workflow  = arguments.workflow
			, reference = arguments.reference
			, owner     = arguments.owner
			, expires   = arguments.expires ?: ""
		});
	}

	public string function appendToState(
		  required struct state
		, required string status
		,          string workflow   = ""
		,          string reference  = ""
		,          string owner      = _getCookieBasedOwner()
		,          string id         = _getRecordIdByWorkflowNameReferenceAndOwner( arguments.workflow, arguments.reference, arguments.owner )
		,          date   expires

	) {
		var existingWf = getState( argumentCollection=arguments );
		var newState   = existingWf.state ?: {};

		newState.append( arguments.state );

		return saveState( argumentCollection=arguments, state=newState );
	}

	public struct function getState(
		  string workflow   = ""
		, string reference  = ""
		, string owner      = _getCookieBasedOwner()
		, string id         = _getRecordIdByWorkflowNameReferenceAndOwner( arguments.workflow, arguments.reference, arguments.owner )
	) {
		if ( Len( Trim( arguments.id  ) ) ) {
			var record = _getStateDao().selectData( id=arguments.id );

			if ( _hasStateExpired( record.expires ) ) {
				complete( id=record.id );
				return {};
			}

			for( var r in record ){
				r.state = IsJson( r.state ) ? DeserializeJson( r.state ) : {};
				return r;
			}
		}

		return {};
	}

	public boolean function complete(
		  string workflow   = ""
		, string reference  = ""
		, string owner      = _getCookieBasedOwner()
		, string id         = _getRecordIdByWorkflowNameReferenceAndOwner( arguments.workflow, arguments.reference, arguments.owner )
	) {
		if ( Len( Trim( arguments.id ) ) ) {
			return _getStateDao().deleteData( id=arguments.id );
		}
		return false;
	}

// PRIVATE HELPERS
	private string function _getRecordIdByWorkflowNameReferenceAndOwner( required string workflow, required string reference, required string owner ) {
		if ( Len( Trim( arguments.workflow ) ) && Len( Trim( arguments.reference ) ) && Len( Trim( arguments.owner ) ) ) {
			var record = _getStateDao().selectData(
				  selectFields = [ "id", "expires" ]
				, filter       = { workflow=arguments.workflow, reference=arguments.reference, owner=arguments.owner }
			);

			if ( _hasStateExpired( record.expires ) ) {
				complete( id=record.id );
				return "";
			}

			if ( !record.recordCount && owner != _getCookieBasedOwner() ) {
				record = _getStateDao().selectData(
					  selectFields = [ "id" ]
					, filter       = { workflow=arguments.workflow, reference=arguments.reference, owner=_getCookieBasedOwner() }
				);

				if ( record.recordCount ) {
					_getStateDao().updateData( id=record.id, data={ owner = arguments.owner } );
				}
			}

			return record.id ?: "";
		}

		return "";
	}

	private string function _getCookieBasedOwner() {
		var cookieService = _getCookieService();
		var cookieKey     = _getCookieKey();
		var owner         = cookieService.getVar( cookieKey, "" );

		if ( !Len( Trim( owner ) ) ) {
			var owner = CreateUUId();
			cookieService.setVar( name=cookieKey, value=owner, httpOnly=true );
		}

		return owner;
	}

	private boolean function _hasStateExpired( required any expires ) {
		return IsDate( arguments.expires ) && Now() > expires;
	}

// GETTERS AND SETTERS
	private any function _getStateDao() {
		return _stateDao;
	}
	private void function _setStateDao( required any stateDao ) {
		_stateDao = arguments.stateDao;
	}

	private any function _getCookieService() {
		return _sessionStorage;
	}
	private void function _setCookieService( required any cookieService ) {
		_sessionStorage = arguments.cookieService;
	}

	private string function _getCookieKey() {
		return _cookieKey;
	}
	private void function _setCookieKey( required string cookieKey ) {
		_cookieKey = arguments.cookieKey;
	}
}