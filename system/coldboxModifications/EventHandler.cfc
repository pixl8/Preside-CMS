/**
 * Preside compatibility shim for ColdBox 6.0+
 *
 * ColdBox 6.0 removed setNextEvent() and getModel() from FrameworkSupertype.
 * This shim adds them back so that all Preside handlers continue to work
 * without needing to update 400+ call sites.
 */
component extends="coldbox.system.EventHandler" {

	/**
	 * Compatibility: setNextEvent() was removed in ColdBox 6.0.
	 * Delegates to relocate() which is the replacement.
	 */
	void function setNextEvent(
		  event
		, URL
		, URI
		, queryString
		, persist
		, struct  persistStruct
		, boolean addToken
		, boolean ssl
		, baseURL
		, boolean postProcessExempt
		, numeric statusCode
	){
		controller.relocate( argumentCollection=arguments );
	}

	/**
	 * Compatibility: getModel() was removed in ColdBox 6.0.
	 * Delegates to getInstance() which is the replacement.
	 */
	function getModel( name, dsl, initArguments={} ){
		return getInstance( argumentCollection=arguments );
	}

}
