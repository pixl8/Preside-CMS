/**
 * Service that provides functionality around cloning preside
 * object records.
 *
 * @presideService true
 * @singleton      true
 * @autodoc        true
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns an array of fieldnames for properties that are clonable for the
	 * given object.
	 *
	 * @autodoc true
	 * @objectName Name of the object whose list of fields you wish to get
	 *
	 */
	public array function listCloneableFields( required string objectName ) {
		var cloneable         = [];
		var poService         = $getPresideObjectService();
		var props             = poService.getObjectProperties( objectName=objectName );
		var idField           = poService.getIdField( objectName=objectName );
		var dateCreatedField  = poService.getDateCreatedField( objectName=objectName );
		var dateModifiedField = poService.getDateModifiedField( objectName=objectName );
		var ignoreFields      = [ idField, dateCreatedField, dateModifiedField ];

		for( var propName in props ) {
			var prop        = props[ propName ];
			var isCloneable = prop.cloneable ?: "";

			if ( IsBoolean( isCloneable ) && !isCloneable ) {
				continue;
			}

			if ( ignoreFields.findNoCase( propName ) ) {
				continue;
			}

			if ( Len( Trim( prop.formula ?: "" ) ) ) {
				continue;
			}

			if ( !IsBoolean( isCloneable ) ) {
				if ( Len( Trim( prop.uniqueIndexes ?: "" ) ) ) {
					continue;
				}

				if ( ( prop.relationship ?: "" ) == "one-to-many" ) {
					continue;
				}
			}

			cloneable.append( propName );
		}

		return cloneable;
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS

}