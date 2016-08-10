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
	 * Renders a saved configuration for a field for the given
	 * field type. i.e. the text that is displayed in the condition
	 * builder wizard. For example, "High flyers" below:
	 * \n
	 * > User belongs to group ("High flyers")
	 *
	 * @autodoc
	 * @fieldType.hint          Name of the fieldtype
	 * @value.hint              Saved value to render
	 * @fieldConfiguration.hint Fieldt type configuration options for the specific field
	 *
	 */
	public string function renderConfiguredField(
		  required string fieldType
		, required any    value
		, required struct fieldConfiguration
	) {
		var handler = getHandlerForFieldType( arguments.fieldType );
		var action  = handler & ".renderConfiguredField";
		var coldbox = $getColdbox();

		if ( coldbox.handlerExists( action ) ) {
			return coldbox.runEvent(
				  event          = action
				, private        = true
				, prePostExempt  = true
				, eventArguments = { value=arguments.value, config=arguments.fieldConfiguration }
			);
		}

		return arguments.value;
	}

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