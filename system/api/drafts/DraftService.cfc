component output=false extends="preside.system.base.Service" {

// CONSTRUCTOR
	public any function init() output=false {
		super.init( argumentCollection = arguments );

		return this;
	}

// PUBLIC METHODS
	public boolean function draftExists( required string owner, required string key ) output=false {
		return _getPObj().dataExists( filter={ key = arguments.key, owner=arguments.owner } );
	}

	public any function getDraftContent( required string owner, required string key ) output=false {
		var draft = _getPObj().selectData(
			  filter       = { key = arguments.key, owner=arguments.owner }
			, selectFields = [ "content" ]
		);

		return _deserialize( draft.content );
	}

	public boolean function saveDraft( required string owner, required string key, required any content ) output=false {
		var obj = _getPObj();
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
		return _getPObj().deleteData( filter={ key = arguments.key, owner=arguments.owner } );
	}

// PRIVATE HELPERS
	private any function _getPObj() output=false {
		return getPresideObject( "draft" );
	}

	private string function _serialize( required any content ) output=false {
		return SerializeJson( arguments.content );
	}

	private any function _deserialize( required string serialized ) output=false {
		return DeserializeJson( arguments.serialized );
	}
}