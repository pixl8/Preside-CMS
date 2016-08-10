/**
 * Provides logic for dealing with rules engine field types.
 * For example, rendering field type screens + processing their
 * submissions.
 * \n
 * See [[rules-engine]] for more details.
 *
 * @singleton
 * @presideservice
 * @autodoc
 *
 */
component displayName="RulesEngine Field Type Service" {

// CONSTRUCTOR

	public any function init() {
		return this;
	}

// PUBLIC API

	/**
	 * Returns the handler name to use for the given
	 * field type.
	 *
	 * @autodoc
	 * @fieldType.hint Name of the field type
	 */
	public string function getHandlerForFieldType( required string fieldType ) {
		return "rules.fieldtypes." & arguments.fieldType;
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS

}