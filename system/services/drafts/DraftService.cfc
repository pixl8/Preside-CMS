component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @dao.inject presidecms:object:draft
	 *
	 */
	public any function init( required any dao ) output=false {
		_setDao( arguments.dao );

		return this;
	}

// PUBLIC METHODS
	public boolean function draftExists( required string owner, required string key ) output=false {
		return _getDao().dataExists( filter={ key = arguments.key, owner=arguments.owner } );
	}

	public any function getDraftContent( required string owner, required string key ) output=false {
		var draft = _getDao().selectData(
			  filter       = { key = arguments.key, owner=arguments.owner }
			, selectFields = [ "content" ]
		);

		return _deserialize( draft.content );
	}

	public boolean function saveDraft( required string owner, required string key, required any content ) output=false {
		var obj = _getDao();
		var serialized = _serialize( arguments.content );

		if ( draftExists( owner=arguments.owner, key=arguments.key ) ) {
			return obj.updateData(
				  filter = { key=arguments.key, owner=arguments.owner }
				, data   = { content=serialized }
			);
		} else {
			return Len( obj.insertData( data = {
				  key     = arguments.key
				, owner   = arguments.owner
				, content = _serialize( arguments.content )
				, label = "Draft"
			} ) );
		}
	}

	public numeric function discardDraft( required string owner, required string key ) output=false {
		return _getDao().deleteData( filter={ key = arguments.key, owner=arguments.owner } );
	}

// PRIVATE HELPERS
	private any function _getDao() output=false {
		return _dao;
	}
	private void function _setDao( required any dao ) output=false {
		_dao = arguments.dao;
	}

	private string function _serialize( required any content ) output=false {
		return SerializeJson( arguments.content );
	}

	private any function _deserialize( required string serialized ) output=false {
		return DeserializeJson( arguments.serialized );
	}
}