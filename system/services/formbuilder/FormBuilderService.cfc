/**
 * Provides logic for interacting with form builder forms
 *
 * @singleton
 * @presideservice
 * @autodoc
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API
	/**
	 * Returns the matching database record for the given form ID
	 *
	 * @autodoc
	 * @id.hint ID of the form you wish to get
	 *
	 */
	public query function getForm( required string id ) {
		return Len( Trim( arguments.id ) ) ? $getPresideObject( "formbuilder_form" ).selectData( id=arguments.id ) : QueryNew('');
	}

	/**
	 * Retuns a form's items in an ordered array
	 *
	 * @autodoc
	 * @id.hint ID of the form who's sections and items you wish to get
	 */
	public array function getFormItems( required string id ) {
		var result = [];
		var items  = $getPresideObject( "formbuilder_form" ).selectData(
			  id           = arguments.id
			, sortOrder    = "items.sort_order"
			, forceJoins   = "inner"
			, selectFields = [
				  "items.id"
				, "items.item_type"
				, "items.configuration"
			  ]
		);

		for( var item in items ) {
			result.append( {
				  id            = item.id
				, type          = item.item_type
				, configuration = DeSerializeJson( item.configuration )
			} );
		}

		return result;
	}
}