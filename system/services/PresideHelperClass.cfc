/**
 * @singleton true
 */
component extends="coldbox.system.FrameworkSupertype" accessors=true {

// CONSTRUCTOR
	/**
	 * @controller.inject coldbox
	 *
	 */
	public any function init( required any controller ) {
		variables.controller = arguments.controller;

		super.loadApplicationHelpers();

		return this;
	}

	public any function onMissingMethod( required string missingMethodName, any missingMethodArguments ) {
		if ( IsCustomFunction( variables[ arguments.missingMethodName ] ?: "" ) ) {
			this[ arguments.missingMethodName ] = variables[ arguments.missingMethodName ]; // lazy load

			return variables[ arguments.missingMethodName ]( argumentCollection=arguments.missingMethodArguments );
		}
	}
}