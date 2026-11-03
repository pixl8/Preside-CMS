/**
 * @singleton      true
 * @presideservice true
 * @feature        cms
 */
component {

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

		if ( arguments.object != "page" && !( poService.objectExists( arguments.object ) && poService.isPageType( arguments.object ) ) ) {
			return false;
		}

		try {
			_getSiteTreeService().editPage(
				  id           = arguments.recordId
				, isDraft      = true
				, "#property#" = arguments.content
			);
		} catch ( any e ) {
			$raiseError( e );
			return false;
		}

		return true;
	}

// GETTERS AND SETTERS
	private any function _getSiteTreeService() {
		return _siteTreeService;
	}
	private void function _setSiteTreeService( required any siteTreeService ) {
		_siteTreeService = arguments.siteTreeService;
	}
}

