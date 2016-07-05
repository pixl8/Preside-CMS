component singleton=true {

// CONSTRUCTOR
	/**
	 * @presideObjectService.inject presideObjectService
	 * @siteTreeService.inject      siteTreeService
	 *
	 */
	public any function init( required any presideObjectService, required any siteTreeService ) {
		_setPresideObjectService( arguments.presideObjectService );
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

// GETTERS AND SETTERS
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

