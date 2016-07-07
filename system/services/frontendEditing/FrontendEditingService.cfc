component singleton=true {

// CONSTRUCTOR
	/**
	 * @siteTreeService.inject siteTreeService
	 *
	 */
	public any function init( required any siteTreeService ) {
		_setSiteTreeService( arguments.siteTreeService );

		return this;
	}

// PUBLIC METHODS
	public boolean function saveContent( required string object, required string property, required string recordId, required string content ) {
		var poService = $getPresideObjectService();

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
	private any function _getSiteTreeService() {
		return _siteTreeService;
	}
	private void function _setSiteTreeService( required any siteTreeService ) {
		_siteTreeService = arguments.siteTreeService;
	}
}

