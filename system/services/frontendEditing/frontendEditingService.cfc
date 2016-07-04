component singleton=true {

// CONSTRUCTOR
	/**
	 * @draftService.inject         draftService
	 * @presideObjectService.inject presideObjectService
	 * @siteTreeService.inject      siteTreeService
	 *
	 */
	public any function init( required any draftService, required any presideObjectService, required any siteTreeService ) {
		_setPresideObjectService( arguments.presideObjectService );
		_setDraftService( arguments.draftService );
		_setSiteTreeService( arguments.siteTreeService );

		return this;
	}

// PUBLIC METHODS
	public boolean function saveContent( required string object, required string property, required string recordId, required string content ) {
		var poService = _getPresideObjectService();

		if ( poService.isPageType( arguments.object ) || arguments.object == "page" ) {
			return _getSiteTreeService().editPage(
				  id           = arguments.recordId
				, isDraft      = true
				, "#property#" = arguments.content
			);
		}

		return poService.updateData(
			  objectName = arguments.object
			, data       = { "#property#" = arguments.content }
			, id         = arguments.recordId
			, isDraft    = true
		);
	}

	public boolean function draftExists( required string object, required string property, required string recordId, required string owner ) {
		return _getDraftService().draftExists(
			  key   = _getDraftKey( argumentCollection = arguments )
			, owner = arguments.owner
		);
	}

	public string function getDraft( required string object, required string property, required string recordId, required string owner ) {
		return _getDraftService().getDraftContent(
			  key   = _getDraftKey( argumentCollection = arguments )
			, owner = arguments.owner
		);
	}

	public boolean function saveDraft( required string object, required string property, required string recordId, required string owner, required string content ) {
		return _getDraftService().saveDraft(
			  key     = _getDraftKey( argumentCollection = arguments )
			, owner   = arguments.owner
			, content = arguments.content
		);
	}

	public numeric function discardDraft( required string object, required string property, required string recordId, required string owner ) {
		return _getDraftService().discardDraft(
			  key   = _getDraftKey( argumentCollection = arguments )
			, owner = arguments.owner
		);
	}

// PRIVATE HELPERS
	private string function _getDraftKey( required string object, required string property, required string recordId ) {
		return "frontendedit_" & arguments.object & "-" & arguments.property & "-" & arguments.recordId;
	}

// GETTERS AND SETTERS
	private any function _getDraftService() {
		return _draftService;
	}
	private void function _setDraftService( required any draftService ) {
		_draftService = arguments.draftService;
	}

	private any function _getPresideObjectService() {
		return _presideObjectService;
	}
	private void function _setPresideObjectService( required any presideObjectService ) {
		_presideObjectService = arguments.presideObjectService;
	}

	private any function _getSiteTreeService() {
		return _siteTreeService;
	}
	private void function _setSiteTreeService( required any siteTreeService ) {
		_siteTreeService = arguments.siteTreeService;
	}
}

