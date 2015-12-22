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
	 * Retuns a form's sections and items in a nested array
	 *
	 * @autodoc
	 * @id.hint ID of the form who's sections and items you wish to get
	 */
	public array function getFormItemsBySection( required string id ) {
		var result           = [];
		var sectionsAndItems = $getPresideObject( "formbuilder_form" ).selectData(
			  id           = arguments.id
			, sortOrder    = "sections.sort_order, sections$items.sort_order"
			, selectFields = [
				  "sections.id         as section_id"
				, "items.id            as item_id"
				, "items.item_type     as item_type"
				, "items.configuration as item_configuration"
			  ]
		);
		var sectionNumber  = 0;
		var currentSection = "";

		for( var record in sectionsAndItems ) {
			if ( record.section_id != currentSection ) {
				result.append( { id=record.section_id, items=[] } );

				currentSection = record.section_id;
				sectionNumber  = result.len();
			}

			result[ sectionNumber ].items.append( {
				  id            = record.item_id
				, type          = record.item_type
				, configuration = DeSerializeJson( record.item_configuration )
			} );
		}

		return result;
	}
}