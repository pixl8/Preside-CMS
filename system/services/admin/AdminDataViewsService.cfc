/**
 * Provides logic for dealing with admin views of preside
 * object records such as calculating what renderer to use
 * for fields, locating renderer viewlets and record URLs.
 *
 * @singleton      true
 * @presideService true
 * @autodoc
 */
component {

// CONSTRUCTOR
	/**
	 * @contentRendererService.inject contentRendererService
	 *
	 */
	public any function init( required any contentRendererService ) {
		_setContentRendererService( arguments.contentRendererService );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Renders a field in the context of an admin data view
	 *
	 * @autodoc true
	 * @autodoc           true
	 * @objectName.hint   Name of the object whose property for which you are rendering content
	 * @propertyName.hint Name of the property for which you are rendering content
	 * @recordId.hint     ID of the record to whose content this belongs
	 * @value.hint        Value to render (if any)
	 * @renderer.hint     Renderer to use (will default to calculating the renderer using [[admindataviewsservice-getrendererforfield]])
	 */
	public string function renderField(
		  required string objectName
		, required string propertyName
		, required string recordId
		,          any    value    = ""
		,          string renderer = getRendererForField( objectName=arguments.objectName, propertyName=arguments.propertyName )
	) {

		return _getContentRendererService().render(
			  renderer = arguments.renderer
			, context  = [ "adminview", "admin" ]
			, data     = arguments.value
			, args     = { objectName=arguments.objectName, propertyName=arguments.propertyName, recordId=arguments.recordId }
		);
	}

	/**
	 * Returns either the defined or default admin renderer for the given preside object
	 * property for rendering in an admin record view.
	 *
	 * @autodoc           true
	 * @objectName.hint   Name of the object whose property you wish to get the renderer for
	 * @propertyName.hint Name of the property you wish to get the renderer for
	 */
	public string function getRendererForField( required string objectName, required string propertyName ) {
		var prop = $getPresideObjectService().getObjectProperty(
			  objectName   = arguments.objectName
			, propertyName = arguments.propertyName
		);
		var adminRenderer   = prop.adminRenderer ?: "";
		var generalRenderer = prop.renderer      ?: "";
		var type            = prop.type          ?: "";
		var dbType          = prop.dbType        ?: "";
		var relationship    = prop.relationship  ?: "";

		if ( adminRenderer.trim().len() ) {
			return adminRenderer.trim();
		}

		if ( generalRenderer.trim().len() ) {
			return generalRenderer.trim();
		}

		switch( relationship ) {
			case "many-to-one":
				var relatedTo = prop.relatedTo ?: "";
				switch( relatedTo ) {
					case "asset":
					case "link":
						return relatedTo;
				}
				return "manyToOne";

			case "many-to-many":
			case "one-to-many":
				return "objectRelatedRecords";
		}

		switch( dbtype ) {
			case "text":
			case "mediumtext":
			case "longtext":
				return "richeditor";

			case "boolean":
			case "bit":
				return "boolean";

			case "date":
				return "date";

			case "datetime":
			case "timestamp":
				return "datetime";
		}


		return "plaintext";
	}

	/**
	 * Returns the viewlet to use to render an entire view
	 * of the given object
	 *
	 * @autodoc    true
	 * @objectName Name of the object whose viewlet you wish to get
	 */
	public string function getViewletForObjectRender( required string objectName ) {
		var specificViewlet = $getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "viewRecordViewlet"
		);

		return specificViewlet;
	}

// PRIVATE HELPERS


// GETTERS/SETTERS
	private any function _getContentRendererService() {
		return _contentRendererService;
	}
	private void function _setContentRendererService( required any contentRendererService ) {
		_contentRendererService = arguments.contentRendererService;
	}
}