/**
 * This will eventually be a proper State Machine system (hopfully)
 * For now, just a simple front to a datastore for storing state
 * with a status and owner.
 *
 */
component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @stateDao.inject presidecms:object:workflow_state
	 *
	 */
	public any function init( required any stateDao ) output=false {
		_setStateDao( arguments.stateDao );

		return this;
	}

// PUBLIC API METHODS
	public string function saveState(
		  required struct state
		, required string status
		,          string workflow   = ""
		,          string reference  = ""
		,          string owner      = ""
		,          string id         = _getRecordIdByWorkflowNameReferenceAndOwner( arguments.workflow, arguments.reference, arguments.owner )

	) output=false {
		var serializedState = SerializeJson( arguments.state );

		if ( Len( Trim( arguments.id ) ) ) {
			_getStateDao().updateData(
				  id   = arguments.id
				, data = { state=serializedState, status=arguments.status }
			);

			return arguments.id;
		}

		return _getStateDao().insertData({
			  state     = serializedState
			, status    = arguments.status
			, workflow  = arguments.workflow
			, reference = arguments.reference
			, owner     = arguments.owner
		});
	}

	public struct function getState(
		  string workflow   = ""
		, string reference  = ""
		, string owner      = ""
		, string id         = _getRecordIdByWorkflowNameReferenceAndOwner( arguments.workflow, arguments.reference, arguments.owner )
	) output=false {
		var record = _getStateDao().selectData( id=arguments.id );

		for( var r in record ){
			r.state = IsJson( r.state ) ? DeserializeJson( r.state ) : {};
			return r;
		}

		return {};
	}

	public boolean function complete(
		  string workflow   = ""
		, string reference  = ""
		, string owner      = ""
		, string id         = _getRecordIdByWorkflowNameReferenceAndOwner( arguments.workflow, arguments.reference, arguments.owner )
	) output=false {
		return _getStateDao().deleteData( id=arguments.id );
	}

// PRIVATE HELPERS
	private string function _getRecordIdByWorkflowNameReferenceAndOwner( required string workflow, required string reference, required string owner ) output=false {
		if ( Len( Trim( arguments.workflow ) ) && Len( Trim( arguments.reference ) ) && Len( Trim( arguments.owner ) ) ) {
			var record = _getStateDao().selectData(
				  selectFields = [ "id" ]
				, filter       = { workflow=arguments.workflow, reference=arguments.reference, owner=arguments.owner }
			);

			return record.id ?: "";
		}

		return "";
	}

// GETTERS AND SETTERS
	private any function _getStateDao() output=false {
		return _stateDao;
	}

	private void function _setStateDao( required any stateDao ) output=false {
		_stateDao = arguments.stateDao;
	}

}