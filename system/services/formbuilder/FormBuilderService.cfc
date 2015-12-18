/**
 * @singleton
 * @presideservice
 *
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API
	public query function getForm( required string id ) {
		return Len( Trim( arguments.id ) ) ? $getPresideObject( "formbuilder_form" ).selectData( id=arguments.id ) : QueryNew('');
	}
}