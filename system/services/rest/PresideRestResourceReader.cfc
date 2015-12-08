/**
 * Object that performs parsing of REST resource handlers.
 * The metadata gleaned from the a resource can then be used
 * to map incoming requests to appropriate resource handlers.
 *
 * @autodoc true
 * @singleton
 */
component displayName="Preside REST Resource Reader" {

	/**
	 * Returns whether or not the passed CFC path
	 * represents a valid resource CFC
	 *
	 * @cfcPath.hint Mapped component path to CFC to test the validity of
	 */
	public boolean function isValidResource( required string cfcPath ) {
		var tester = function( meta ){
			if ( arguments.meta.keyExists( "restUri" ) ) {
				return true;
			}
			if ( arguments.meta.keyExists( "extends" ) ) {
				return tester( arguments.meta.extends );
			}

			return false;
		};

		return tester( GetComponentMetaData( arguments.cfcPath ) );
	}


}