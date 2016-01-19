/**
 * Provides logic for validating form builder forms
 *
 * @autodoc
 * @singleton
 * @presideservice
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API
	public array function getStandardRulesForFormField( required string name ) {
		var rules = [];

		if ( IsBoolean( arguments.mandatory ?: "" ) && arguments.mandatory ) {
			rules.append({ fieldname=arguments.name, validator="required" });
		}

		if ( IsNumeric( arguments.maxLength ?: "" ) && arguments.maxLength > 0 ) {
			if ( IsNumeric( arguments.minLength ?: "" ) && arguments.minLength > 0 ) {
				rules.append({ fieldname=arguments.name, validator="rangelength", params={ min=Int( arguments.minLength ), max=Int( arguments.maxLength ) } });
			} else {
				rules.append({ fieldname=arguments.name, validator="maxlength", params={ max=Int( arguments.maxLength ) } });
			}
		} else if ( IsNumeric( arguments.minLength ?: "" ) && arguments.minLength > 0 ) {
			rules.append({ fieldname=arguments.name, validator="minlength", params={ min=Int( arguments.minLength ) } });
		}

		if ( IsNumeric( arguments.maxValue ?: "" ) && arguments.maxValue > 0 ) {
			if ( IsNumeric( arguments.minValue ?: "" ) && arguments.minValue > 0 ) {
				rules.append({ fieldname=arguments.name, validator="range", params={ min=Int( arguments.minValue ), max=Int( arguments.maxValue ) } });
			} else {
				rules.append({ fieldname=arguments.name, validator="maxValue", params={ max=Int( arguments.maxValue ) } });
			}
		} else if ( IsNumeric( arguments.minValue ?: "" ) && arguments.minValue > 0 ) {
			rules.append({ fieldname=arguments.name, validator="minValue", params={ min=Int( arguments.minValue ) } });
		}

		return rules;
	}
}