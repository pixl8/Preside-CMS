component output=false extends="preside.system.base.Service" {

// CONSTRUCTOR
	public any function init( required any draftService ) output=false {
		super.init( argumentCollection = arguments );

		_setDraftService( arguments.draftService );

		return this;
	}

// PUBLIC METHODS
	public boolean function saveContent( required string object, required string property, required string recordId, required string content ) output=false {
		return _getPresideObjectService().updateData(
			  objectName = arguments.object
			, data       = { "#property#" = arguments.content }
			, id         = arguments.recordId
		);
	}

	public boolean function draftExists( required string object, required string property, required string recordId, required string owner ) output=false {
		return _getDraftService().draftExists(
			  key   = _getDraftKey( argumentCollection = arguments )
			, owner = arguments.owner
		);
	}

	public string function getDraft( required string object, required string property, required string recordId, required string owner ) output=false {
		return _getDraftService().getDraftContent(
			  key   = _getDraftKey( argumentCollection = arguments )
			, owner = arguments.owner
		);
	}

	public boolean function saveDraft( required string object, required string property, required string recordId, required string owner, required string content ) output=false {
		return _getDraftService().saveDraft(
			  key     = _getDraftKey( argumentCollection = arguments )
			, owner   = arguments.owner
			, content = arguments.content
		);
	}

	public numeric function discardDraft( required string object, required string property, required string recordId, required string owner ) output=false {
		return _getDraftService().discardDraft(
			  key   = _getDraftKey( argumentCollection = arguments )
			, owner = arguments.owner
		);
	}

// PRIVATE HELPERS
	private string function _getDraftKey( required string object, required string property, required string recordId ) output=false {
		return "frontendedit_" & arguments.object & "-" & arguments.property & "-" & arguments.recordId;
	}

// GETTERS AND SETTERS
	private any function _getDraftService() output=false {
		return _draftService;
	}
	private void function _setDraftService( required any draftService ) output=false {
		_draftService = arguments.draftService;
	}
}

