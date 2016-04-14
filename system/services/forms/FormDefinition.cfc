/**
 * A helper object for creating dynamic form
 * definitions and modififying existing definitions. Provides
 * an API abstraction for adding/modifying and removing fields, fieldsets
 * and tabs
 *
 */
component {

	public any function init( struct rawDefinition={ tabs=[] } ) {
		_setRawDefinition( arguments.rawDefinition );

		return this;
	}

	public struct function getRawDefinition() {
		return _getRawDefinition();
	}


// GETTERS AND SETTERS
	private any function _getRawDefinition() {
		return _rawDefinition;
	}
	private void function _setRawDefinition( required any rawDefinition ) {
		_rawDefinition = arguments.rawDefinition;
	}
}