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
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns either the defined or default admin renderer for the given preside object
	 * property for rendering in an admin record view.
	 *
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


// PRIVATE HELPERS


// GETTERS/SETTERS

}