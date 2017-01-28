/**
 * Preside specific overrides for core coldbox request service.
 * Please note: output=false required due to extending a tag based component
 *
 */
component output=false extends="coldbox.system.web.services.RequestService" {

	/**
	 * When service starts up, add a mockFlashScope to use
	 * for stateless requests.
	 */
	public any function buildFlashScope() {
		super.buildFlashScope( argumentCollection=arguments );

		instance.mockFlashScope = createObject( "component", "coldbox.system.web.flash.MockFlash" ).init( controller, instance.flashData );
	}

	/**
	 * Additional checks for whether or not sessions are enabled.
	 * If not, get our mock flash scope - otherwise, proceed as normal.
	 */
	public any function getFlashScope() output=false {
		var appSettings = GetApplicationSettings( true );

		if ( IsBoolean( appSettings.sessionManagement ?: "" ) && appSettings.sessionManagement ) {
			return super.getFlashScope();
		}

		return instance.mockFlashScope;
	}

}