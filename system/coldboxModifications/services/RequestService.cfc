/**
 * Preside specific overrides for core coldbox request service.
 * Please note: output=false required due to extending a tag based component
 *
 */
component extends="coldbox.system.web.services.RequestService" {

	/**
	 * Use our own session flash scope that protects against
	 * per-request sessions being disabled
	 */
	public any function buildFlashScope() {
		if ( variables.flashData.scope == "session" ){
			variables.flashScope = CreateObject( "component", "preside.system.coldboxModifications.SessionFlash" ).init( controller, variables.flashData );
		} else {
			super.buildFlashScope( argumentCollection=arguments );
		}
	}

}