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

	/**
	 * CB 8.0: FrameworkSupertype added getSystemSetting(key, defaultValue) which
	 * shadows Preside's getSystemSetting(category, setting, default) helper.
	 * Restore Preside's version.
	 */
	function getSystemSetting(){
		return getInstance( "systemConfigurationService" ).getSetting( argumentCollection=arguments );
	}

	/**
	 * CB 7.0: renderView() deprecated and no longer returns a value.
	 * Restore the return so Preside handlers get their rendered content.
	 */
	function renderView(){
		return getRenderer().renderView( argumentCollection=arguments );
	}

	/**
	 * CB 7.0: renderLayout() deprecated and no longer returns a value.
	 * Restore the return so Preside handlers get their rendered content.
	 */
	function renderLayout(){
		return getRenderer().renderLayout( argumentCollection=arguments );
	}

	/**
	 * CB 7.0: layout() replaced renderLayout() in FrameworkSupertype.
	 * Override to prevent infinite recursion via FrameworkSupertype.layout() -> getRenderer().layout()
	 */
	function layout(){
		return getRenderer().renderLayout( argumentCollection=arguments );
	}

	/**
	 * CB 7.0: renderExternalView() deprecated and no longer returns a value.
	 */
	function renderExternalView(){
		return getRenderer().renderExternalView( argumentCollection=arguments );
	}

}
