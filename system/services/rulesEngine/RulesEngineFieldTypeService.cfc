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
	 * @fieldConfiguration.hint Field type configuration options for the specific field
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
	 * Renders the configuration screen for the given field type
	 * and field configuration. The configuration screen appears
	 * when a user clicks on an editable field within an inserted
	 * expression in the condition builder.
	 *
	 * @autodoc
	 * @fieldType.hint          Name of the fieldtype
	 * @currentValue.hint       The current saved value for the field within the expression
	 * @fieldConfiguration.hint Field type configuration options for the specific field
	 */
	public string function renderConfigScreen(
		  required string fieldType
		, required any    currentValue
		, required struct fieldConfiguration
	) {
		var handler = getHandlerForFieldType( arguments.fieldType );
		var action  = handler & ".renderConfigScreen";
		var coldbox = $getColdbox();

		if ( coldbox.handlerExists( action ) ) {
			return $getColdbox().runEvent(
				  event         = action
				, private       = true
				, prePostExempt = true
				, eventArguments = { value=arguments.currentValue, config=arguments.fieldConfiguration }
			);
		}

		throw( type="preside.rules.fieldtype.missing.config.screen", message="The field type, [#arguments.fieldType#], has no [renderConfigScreen] handler with which to show a configuration screen" );
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